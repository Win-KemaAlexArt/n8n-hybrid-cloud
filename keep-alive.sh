#!/bin/bash
echo "✅ Keep-alive script started. Codespace will not sleep."
while true; do
  echo "[$(date)] Still alive..."
  sleep 300 # Sleep for 5 minutes (300 seconds)
done
