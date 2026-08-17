#!/bin/zsh
# 临时脚本：批量抓取同花顺问财主力资金流向（headless 本地模式）
OUT=/Users/Administrator1/stock-reports-site/logs/iwencai_flow.jsonl
LOG=/Users/Administrator1/stock-reports-site/logs/iwencai_fetch.log
: > "$OUT"
: > "$LOG"

stocks=(
"澜起科技|sh688008"
"中际旭创|sz300308"
"扬杰科技|sz300373"
"中钨高新|sz000657"
"普冉股份|sh688766"
"佰维存储|sh688525"
"长鑫科技|sh688825"
"紫光国微|sz002049"
"新易盛|sz300502"
"华友钴业|sh603799"
"立讯精密|sz002475"
"环旭电子|sh601231"
"科华数据|sz002335"
"四方达|sz300179"
"紫金矿业|sh601899"
"大华股份|sz002236"
"宁德时代|sz300750"
"汉得信息|sz300170"
"华测导航|sz300627"
"科大讯飞|sz002230"
"青岛啤酒|sh600600"
)

EVAL='(() => { const t = document.body.innerText; const m = t.match(/今天资金(净流入|净流出)\s*([\d.]+)\s*亿(?:元)?[，,]\s*其中流入\s*([\d.]+)\s*亿(?:元)?[，,]\s*流出\s*([\d.]+)\s*亿(?:元)?/); const trend = t.match(/近5日资金总体[^。]*。/); let net = null; if (m) { net = parseFloat(m[2]) * (m[1] === "净流入" ? 1 : -1); } return JSON.stringify({dir: m?m[1]:null, net: net, inflow: m?parseFloat(m[3]):null, outflow: m?parseFloat(m[4]):null, trend5d: trend?trend[0]:null}); })()'

for entry in $stocks; do
  name="${entry%%|*}"
  code="${entry##*|}"
  q=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${name} 资金流向'))")
  browse open "https://www.iwencai.com/stockpick/search?w=${q}" --local --headless -s iwencai --timeout 60000 >/dev/null 2>&1
  sleep 8
  # 提取 eval 输出的 JSON（result 字段）
  inner=$(browse eval "$EVAL" --local -s iwencai 2>/dev/null | python3 -c '
import sys, json
s = sys.stdin.read()
try:
    o = json.loads(s)
    print(o.get("result", "") if isinstance(o, dict) else "")
except Exception:
    print("")
')
  echo "{\"name\":\"${name}\",\"code\":\"${code}\",\"flow\":${inner}}" >> "$OUT"
  echo "[$(date +%H:%M:%S)] ${name} ${code} -> ${inner}" >> "$LOG"
  sleep 1
done

echo "ALL_DONE"
