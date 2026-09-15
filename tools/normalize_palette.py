#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
normalize_palette.py — 把生成稿里漂移出去的强调色归一化回合规色板。

背景（2026-09-15）：日报/热点页面由 `claude -p` 每天重新生成，提示词只说
「参照 hotspot/ 最新模板」，没有颜色规范，于是模型把它当强调色随手加、
逐期漂移。累计到 127 个页面里 9,221 处用了低对比度色值作文字色：

    #f39c12  橙黄   白底 2.19:1   ← 用户反馈「黄色字看不清」
    #ffe082  浅琥珀 白底 1.29:1   ← 几乎等于白底白字
    #27ae60  绿     白底 2.87:1
    #e74c3c  红     白底 3.82:1
    （WCAG AA 对正文要求 4.5:1）

SKILL.md 已写入色板与「禁止内联颜色」规则，但提示词约束是概率性的，
模型可能不遵守。本脚本是**确定性兜底**：不管模型写成什么，部署前一律归一。

用法：
    normalize_palette.py <file.html> [...]      归一化（就地改写）
    normalize_palette.py --check <file.html>    只体检，不写

退出码（供 shell 决定是否要重新部署）：
    0   无需改动（或出错——本脚本永不因错误中断流水线）
    10  有改动，已就地重写
"""

from __future__ import annotations

import os
import re
import sys

# 漂移色 → 色板色。语义层级不变，只是压暗到 AA 合规。
FIX = {
    "f39c12": "9c5a00",   # 橙黄 → 深琥珀
    "ffe082": "9c5a00",   # 浅琥珀 → 深琥珀
    "e67e22": "9c5a00",   # 深橙 → 深琥珀
    "27ae60": "1e7d3c",   # 亮绿 → 深绿
    "e74c3c": "c0392b",   # 亮红 → 深红
}
_PAT = re.compile("|".join(FIX), re.I)


def normalize(text: str) -> tuple[str, int]:
    n = 0

    def sub(m: re.Match) -> str:
        nonlocal n
        n += 1
        return FIX[m.group(0).lower()]

    return _PAT.sub(sub, text), n


def main() -> int:
    argv = [a for a in sys.argv[1:] if a != "--check"]
    check_only = "--check" in sys.argv
    if not argv:
        sys.stderr.write(__doc__)
        return 0  # 不中断流水线

    total = 0
    changed = 0
    for path in argv:
        path = os.path.expanduser(path)
        if not os.path.isfile(path):
            continue
        try:
            with open(path, encoding="utf-8") as fh:
                text = fh.read()
        except OSError:
            continue
        new, n = normalize(text)
        if not n:
            continue
        total += n
        if check_only:
            print(f"  ⚠️ {os.path.basename(path)}：{n} 处漂移色值")
            continue
        try:
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(new)
            changed += 1
        except OSError:
            continue

    if check_only:
        return 10 if total else 0
    if not total:
        return 0
    print(f"  🔧 配色归一化：{changed} 个文件 {total} 处 → 合规色板")
    return 10


if __name__ == "__main__":
    sys.exit(main())
