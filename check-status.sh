#!/bin/bash

echo "🕵️  Checking system status..."

echo "
--- 1. N8N Process ---"
ps aux | grep 'n8n start' | grep -v grep || echo "❌ N8N is not running."

echo "
--- 2. Keep-Alive Process ---"
ps aux | grep 'keep-alive.sh' | grep -v grep || echo "❌ Keep-alive script is not running."

echo "
--- 3. Keep-Alive Log ---"
if [ -f keep-alive.log ]; then
  echo "Last 5 entries:"
  tail -n 5 keep-alive.log
else
  echo "❌ keep-alive.log not found."
fi

echo "
--- 4. Latest Git Commit ---"
git log -1 --oneline

echo "
✅ Status check complete."
