#!/bin/zsh
# 自动补跑 — 每10分钟由 launchd 触发，工作日当天报告缺失则补生成
# 覆盖"早上合盖睡眠错过9:00/11:00定时任务"的情况：电脑一唤醒，10分钟内自动补上。
export PATH="/Users/Administrator1/.npm-global/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export HOME="/Users/Administrator1"

LOG_DIR="/Users/Administrator1/stock-reports-site/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/auto_catchup.log"

DOW=$(date +%u)   # 1=周一 ... 7=周日
if [ "$DOW" -gt 5 ]; then
  exit 0   # 非工作日不补
fi

TODAY=$(date +%F)
cd /Users/Administrator1/stock-reports-site || exit 1

DAILY_EXISTS=$([ -f "daily/$TODAY.html" ] && echo 1 || echo 0)
HOTSPOT_EXISTS=$([ -f "hotspot/$TODAY.html" ] && echo 1 || echo 0)
echo "$(date '+%F %T') catchup检查: daily=$DAILY_EXISTS hotspot=$HOTSPOT_EXISTS" >> "$LOG"

if [ "$DAILY_EXISTS" -eq 0 ]; then
  echo "$(date '+%F %T') 检测到 daily 缺失，触发补跑" >> "$LOG"
  /bin/zsh /Users/Administrator1/stock-reports-site/auto_daily.sh >> "$LOG" 2>&1
fi

if [ "$HOTSPOT_EXISTS" -eq 0 ]; then
  echo "$(date '+%F %T') 检测到 hotspot 缺失，触发补跑" >> "$LOG"
  /bin/zsh /Users/Administrator1/stock-reports-site/auto_hotspot.sh >> "$LOG" 2>&1
fi
