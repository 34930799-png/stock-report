#!/bin/zsh
# 重试抓取 null 股票（改进正则，兼容 万元/亿元 及不同趋势表述）
OUT=/Users/Administrator1/stock-reports-site/logs/iwencai_flow.jsonl
LOG=/Users/Administrator1/stock-reports-site/logs/iwencai_retry.log
: > "$LOG"

stocks=(
"扬杰科技|sz300373"
"中钨高新|sz000657"
"紫光国微|sz002049"
"华友钴业|sh603799"
"环旭电子|sh601231"
"科华数据|sz002335"
"四方达|sz300179"
"大华股份|sz002236"
"汉得信息|sz300170"
"华测导航|sz300627"
"青岛啤酒|sh600600"
)

EVAL='(() => { const t = document.body.innerText; const m = t.match(/今天资金(净流入|净流出)\s*([\d.]+)\s*(亿|万)元?[，,]\s*其中流入\s*([\d.]+)\s*(亿|万)元?[，,]\s*流出\s*([\d.]+)\s*(亿|万)元?/); const trend5 = t.match(/近5日资金总体[^。]*。/); const trend2 = t.match(/近日资金[^。]*。/); const toYi = (v,u) => (u === "万" ? parseFloat(v)/10000 : parseFloat(v)); let net = null, inflow = null, outflow = null; if (m) { net = toYi(m[2],m[3]) * (m[1] === "净流入" ? 1 : -1); inflow = toYi(m[4],m[5]); outflow = toYi(m[6],m[7]); } const trend5d = (trend5 ? trend5[0] : (trend2 ? trend2[0] : null)); return JSON.stringify({dir: m?m[1]:null, net: net, inflow: inflow, outflow: outflow, trend5d: trend5d}); })()'

for entry in $stocks; do
  name="${entry%%|*}"
  code="${entry##*|}"
  q=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${name} 资金流向'))")
  browse open "https://www.iwencai.com/stockpick/search?w=${q}" --local --headless -s iwencai --timeout 60000 >/dev/null 2>&1
  sleep 12
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

echo "RETRY_DONE"
