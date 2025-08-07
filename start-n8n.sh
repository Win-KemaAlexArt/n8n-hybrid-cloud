#!/bin/bash

echo "🚀 Starting N8N Hybrid Cloud Setup..."

# Install n8n globally
echo "📦 Installing n8n..."
npm install -g n8n

# Set environment variables
export N8N_HOST=0.0.0.0
export N8N_PORT=5678
export N8N_PROTOCOL=https
export WEBHOOK_URL=https://$(hostname)-5678.githubpreview.dev

echo "🌐 N8N will be available at: $WEBHOOK_URL"

# Start n8n
echo "🎯 Starting n8n server..."
n8n start
