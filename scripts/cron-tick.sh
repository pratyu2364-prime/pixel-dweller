#!/usr/bin/env bash
# Cron entry point. Sources the user environment (cron has a minimal PATH/env),
# then runs ONE task of the autonomous loop. Logs to cron.log.
source "$HOME/.profile" 2>/dev/null
source "$HOME/.bashrc" 2>/dev/null
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$HOME/.local/share/opencode/bin:$PATH"
cd "$HOME/pixel-dweller" || exit 1
echo "===== cron tick $(date '+%F %T') =====" >> cron.log
exec bash scripts/dev-loop.sh once >> cron.log 2>&1
