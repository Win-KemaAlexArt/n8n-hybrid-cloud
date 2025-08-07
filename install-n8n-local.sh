#!/bin/bash

echo "🚀 Installing N8N Locally (without global permissions)..."

# Create local node_modules directory
mkdir -p ~/.local/bin
mkdir -p ~/.local/lib/node_modules

# Install n8n locally
echo "📦 Installing n8n locally..."
npm config set prefix ~/.local
npm install -g n8n

# Add to PATH
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
export PATH=$HOME/.local/bin:$PATH

# Verify installation
echo "✅ Verifying n8n installation..."
n8n --version

# Set environment variables
export N8N_HOST=0.0.0.0
export N8N_PORT=5678
export N8N_PROTOCOL=https
export WEBHOOK_URL=https://$(hostname)-5678.githubpreview.dev

echo "🌐 N8N will be available at: $WEBHOOK_URL"

# Start n8n
echo "🎯 Starting n8n server..."
n8n start
