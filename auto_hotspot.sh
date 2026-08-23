#!/bin/zsh
# 股票热点关注 自动生成 — launchd 工作日 11:00 触发（数据以交易日 11:00 时点为准，上午盘中实时）
export PATH="/Users/Administrator1/.npm-global/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export HOME="/Users/Administrator1"

# Cloudflare 部署凭证：优先读长期 API Token（避免 OAuth 过期导致部署失败）
CF_TOKEN_FILE="$HOME/.config/cloudflare/api_token"
if [ -f "$CF_TOKEN_FILE" ]; then
  export CLOUDFLARE_API_TOKEN="$(cat "$CF_TOKEN_FILE")"
  export CLOUDFLARE_ACCOUNT_ID="f187aa4998892eea49cc78c0c6729043"
fi

LOG_DIR="/Users/Administrator1/stock-reports-site/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/auto_hotspot.log"

DOW=$(date +%u)   # 1=周一 ... 7=周日
if [ "$DOW" -gt 5 ]; then
  echo "$(date '+%F %T') 非工作日(周$DOW)，跳过" >> "$LOG"
  exit 0
fi

TODAY=$(date +%F)
echo "$(date '+%F %T') ==== 开始生成股票热点关注 hotspot（$TODAY，11:00盘中数据）====" >> "$LOG"
cd /Users/Administrator1/stock-reports-site || exit 1

# 防并发锁：同一天只允许一个生成任务运行（daily/hotspot/catchup 共享）
python3 -c "
import fcntl,sys
f=open('/tmp/stock_report.lock','a')
try:
    fcntl.flock(f, fcntl.LOCK_EX|fcntl.LOCK_NB)
except OSError:
    sys.exit(0)
" || exit 0

claude -p --dangerously-skip-permissions "使用 stock-report skill 全自动生成今日股票热点关注(hotspot)。数据以交易日早上11:00时点为准（上午盘中实时数据）。流程：1) 用新浪API curl 抓取大盘指数(sh000001,sz399001,sz399006,sh000688)和23只自选股实时行情，必须带 --referer https://finance.sina.com.cn 2) 用同花顺问财 browse CLI 本地模式抓取每只自选股主力资金流向(含近5日趋势)，抓不到就用量价推断降级方案 3) 用 WebSearch 或 Firecrawl 搜索当日要闻/板块热点/涨停复盘 4) 参照 hotspot/ 目录最新模板格式，只生成 hotspot/$TODAY.html（需>15KB），不生成 daily 5) git add hotspot/$TODAY.html && git commit -m 'auto: $TODAY 股票热点' && git push github master 6) cd ~/stock-reports-site && npx wrangler pages deploy . --project-name=jiating-gupiao --branch=main 7) curl -s -o /dev/null -w '%{http_code}' https://jiating-gupiao.pages.dev/hotspot/$TODAY 必须返回200。所有操作全自动无需确认，非致命错误(如个别股票数据缺失)自动降级继续不中断，全部跑完才算完成。" >> "$LOG" 2>&1

RC=$?
echo "$(date '+%F %T') ==== hotspot 任务结束，退出码 $RC ====" >> "$LOG"
exit $RC
