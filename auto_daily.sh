#!/bin/zsh
# 关注股票日报 自动生成 — launchd 工作日 9:00 触发（数据以交易日 9:00 时点为准）
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
LOG="$LOG_DIR/auto_daily.log"

DOW=$(date +%u)   # 1=周一 ... 7=周日
if [ "$DOW" -gt 5 ]; then
  echo "$(date '+%F %T') 非工作日(周$DOW)，跳过" >> "$LOG"
  exit 0
fi

TODAY=$(date +%F)
echo "$(date '+%F %T') ==== 开始生成关注股票日报 daily（$TODAY，9:00数据）====" >> "$LOG"
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

claude -p --dangerously-skip-permissions "使用 stock-report skill 全自动生成今日关注股票日报(daily)。数据以交易日早上9:00时点为准（盘前：前日收盘+隔夜消息+今日预判）。流程：1) 用新浪API curl 抓取大盘指数(sh000001,sz399001,sz399006,sh000688)和23只自选股行情，必须带 --referer https://finance.sina.com.cn 2) 用同花顺问财 browse CLI 本地模式抓取每只自选股主力资金流向(含近5日趋势)，抓不到就用量价推断降级方案 3) 用 WebSearch 或 Firecrawl 搜索当日要闻 4) 参照 daily/ 目录最新模板格式，只生成 daily/$TODAY.html（需>20KB），不生成 hotspot 5) git add daily/$TODAY.html && git commit -m 'auto: $TODAY 股票日报' && git push github master 6) cd ~/stock-reports-site && npx wrangler pages deploy . --project-name=jiating-gupiao --branch=main 7) curl -s -o /dev/null -w '%{http_code}' https://jiating-gupiao.pages.dev/daily/$TODAY 必须返回200。所有操作全自动无需确认，非致命错误(如个别股票数据缺失)自动降级继续不中断，全部跑完才算完成。" >> "$LOG" 2>&1

RC=$?
echo "$(date '+%F %T') ==== daily 任务结束，退出码 $RC ====" >> "$LOG"
exit $RC
