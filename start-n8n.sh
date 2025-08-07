#!/bin/bash

# Enable strict error checking and command echoing for debugging
set -ex

echo "🚀 DEBUG MODE: Starting N8N Hybrid Cloud Setup..."
echo "---"
echo "STEP 1: Setting environment variables..."

export N8N_HOST=0.0.0.0
export N8N_PORT=5678
export N8N_PROTOCOL=https
export WEBHOOK_URL="https://$(hostname)-5678.githubpreview.dev"
export N8N_RUNNERS_ENABLED=true

echo "-> WEBHOOK_URL set to: $WEBHOOK_URL"
echo "---"
echo "STEP 2: Launching keep-alive script..."

chmod +x keep-alive.sh
# Launch in background, redirecting stdout and stderr to a log file
./keep-alive.sh > keep-alive.log 2>&1 &
KEEPALIVE_PID=$!

echo "-> Keep-alive script launched with PID: $KEEPALIVE_PID"
echo "---"
echo "STEP 3: Starting n8n server..."

# Start n8n in the foreground
n8n start

echo "---"
echo "🏁 Script finished (or n8n process stopped)."
