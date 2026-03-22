#!/bin/bash
# Hook script: injects config repo context when user mentions config sync/push/pull
input=$(cat)
if echo "$input" | grep -qiE '(sync|pull|push|update)\s*(the\s+)?(claude\s+)?config'; then
  cat ~/Work/claude-config/mapping.md
fi
