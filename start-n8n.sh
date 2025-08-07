#!/bin/bash

echo "🚀 Starting N8N Hybrid Cloud Setup..."

# Set environment variables
export N8N_HOST=0.0.0.0
export N8N_PORT=5678
export N8N_PROTOCOL=https
export WEBHOOK_URL=https://$(hostname)-5678.githubpreview.dev
export N8N_RUNNERS_ENABLED=true # Recommended by n8n to avoid future issues

echo "🌐 N8N will be available at: $WEBHOOK_URL"

# Start keep-alive script in the background and log its output
echo "🚀 Starting keep-alive process..."
chmod +x keep-alive.sh
./keep-alive.sh > keep-alive.log 2>&1 &

# Get the Process ID (PID) of the keep-alive script
KEEPALIVE_PID=$!
echo "✅ Keep-alive script started in the background with PID: $KEEPALIVE_PID"
echo "   You can check its logs with: tail -f keep-alive.log"

# Start n8n in the foreground
echo "🎯 Starting n8n server..."
n8n start
