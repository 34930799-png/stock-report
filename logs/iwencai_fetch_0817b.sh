#!/bin/zsh
# 2026-08-17 盘前：批量抓取同花顺问财主力资金流向（新页面结构）
OUT=/Users/Administrator1/stock-reports-site/logs/iwencai_flow_0817.jsonl
LOG=/Users/Administrator1/stock-reports-site/logs/iwencai_fetch_0817b.log
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

EVAL='(() => { const t = document.body.innerText; const dir = t.match(/(?:今日|今天)资金(?:呈|呈现)?(净流入|净流出)状态/); const flow = t.match(/实时资金流向[:：]\s*([+\-]?[\d.]+)\s*(亿|万)元/); const trend5 = t.match(/近5日资金总体[^。]*。/); const trend2 = t.match(/近日资金[^。]*。/); const narr = t.match(/(?:今日|今天)资金[^。]*。([^。]*。)/); const toYi = (v,u) => (u === "万" ? parseFloat(v)/10000 : parseFloat(v)); let net = null; if (flow) { net = toYi(flow[1], flow[2]) * (dir && dir[1] === "净流出" ? -1 : (dir && dir[1] === "净流入" ? 1 : (parseFloat(flow[1]) < 0 ? 1 : 1))); } const trend5d = (trend5 ? trend5[0] : (trend2 ? trend2[0] : null)); const narrative = narr ? narr[0] : null; return JSON.stringify({dir: dir?dir[1]:null, net: net, flowRaw: flow?flow[1]+flow[2]:null, trend5d: trend5d, narrative: narrative}); })()'

for entry in $stocks; do
  name="${entry%%|*}"
  code="${entry##*|}"
  q=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${name} 资金流向'))")
  browse open "https://www.iwencai.com/stockpick/search?w=${q}" --local --headless -s iwencai --timeout 60000 >/dev/null 2>&1
  sleep 10
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

echo "ALL_DONE_0817B"
