#!/bin/bash

echo "🚀 Starting N8N Hybrid Cloud Setup..."

# Install n8n globally with sudo
echo "📦 Installing n8n..."
sudo npm install -g n8n

# Set environment variables
export N8N_HOST=0.0.0.0
export N8N_PORT=5678
export N8N_PROTOCOL=https
export WEBHOOK_URL=https://$(hostname)-5678.githubpreview.dev
export N8N_RUNNERS_ENABLED=true # Recommended by n8n to avoid future issues

echo "🌐 N8N will be available at: $WEBHOOK_URL"

# Start keep-alive script in the background
chmod +x keep-alive.sh
./keep-alive.sh & # The '&' runs it in the background

# Start n8n in the foreground
echo "🎯 Starting n8n server..."
n8n start
