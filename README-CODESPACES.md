# 🚀 N8N Hybrid Cloud - GitHub Codespaces Setup

## Quick Start

1. **Launch Codespace** from GitHub repository
2. **Run startup script:**
   ```bash
   chmod +x start-n8n.sh
   ./start-n8n.sh
   ```
3. **Access N8N UI** via the forwarded port (5678)

## Environment Details

- **Runtime:** Node.js 18
- **N8N Port:** 5678
- **Webhook Gateway:** Deployed on Vercel
- **Database:** Optional Supabase integration

## Codespace Configuration

The `.devcontainer/devcontainer.json` is optimized for:
- ✅ Minimal disk usage
- ✅ Fast startup
- ✅ No Docker overhead
- ✅ Direct n8n installation

## Troubleshooting

### If n8n fails to start:
```bash
# Check Node.js version
node --version

# Reinstall n8n
npm uninstall -g n8n
npm install -g n8n

# Start manually
n8n start --host 0.0.0.0 --port 5678
```

### Access Issues:
- Ensure port 5678 is forwarded in Codespace
- Check if n8n is running: `ps aux | grep n8n`
- View logs: `n8n start --verbose`

## Next Steps

1. Configure webhook URLs in your bots
2. Import workflows from `workflows/` directory
3. Set up Supabase connection (optional)
4. Test webhook gateway integration
