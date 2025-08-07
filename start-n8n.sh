#!/bin/bash

# Set environment variables
export N8N_HOST=0.0.0.0
export N8N_PORT=5678
export N8N_PROTOCOL=https
export WEBHOOK_URL="https://$(hostname)-5678.githubpreview.dev"
export N8N_RUNNERS_ENABLED=true

echo "✅ N8N Environment variables set."
echo "   Webhook URL: $WEBHOOK_URL"

# Start keep-alive script in the background
chmod +x keep-alive.sh
./keep-alive.sh > keep-alive.log 2>&1 &
KEEPALIVE_PID=$!

echo "✅ Keep-alive script started in the background (PID: $KEEPALIVE_PID)."

# Start n8n in the foreground
echo "🚀 Starting n8n server..."
n8n start
