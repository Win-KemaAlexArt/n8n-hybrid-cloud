# 🚨 EMERGENCY N8N SETUP - CURRENT CODESPACE

## 🔥 IMMEDIATE SOLUTION (30 seconds):

```bash
# Method 1: Quick Fix with sudo
chmod +x quick-fix.sh
./quick-fix.sh
```

```bash
# Method 2: Local Installation (no sudo needed)
chmod +x install-n8n-local.sh
./install-n8n-local.sh
```

```bash
# Method 3: Manual Commands
sudo npm install -g n8n
n8n start --host 0.0.0.0 --port 5678
```

## 🎯 ACCESS N8N:
- **URL:** https://codespaces-14eef1-5678.githubpreview.dev
- **Port:** 5678 (auto-forwarded)
- **Protocol:** HTTPS

## 🔧 TROUBLESHOOTING:

### If sudo fails:
```bash
# Use local installation
npm config set prefix ~/.local
npm install -g n8n
export PATH=$HOME/.local/bin:$PATH
n8n start --host 0.0.0.0 --port 5678
```

### If port not accessible:
```bash
# Check if n8n is running
ps aux | grep n8n

# Kill existing process
pkill -f n8n

# Restart with verbose logging
n8n start --host 0.0.0.0 --port 5678 --verbose
```

### If Node.js version issues:
```bash
# Check version
node --version

# Should be 20.x.x for current codespace
# If 18.x.x, rebuild codespace with updated config
```

## ⚡ NEXT STEPS AFTER N8N STARTS:

1. **Access UI** via forwarded port
2. **Set admin credentials** (first login)
3. **Import workflows** from `/workspaces/n8n-hybrid-cloud/workflows/`
4. **Configure webhook URLs** in bots
5. **Test Vercel gateway** integration

## 🌐 WEBHOOK GATEWAY:
- **Vercel URL:** https://n8n-webhook-gateway.vercel.app
- **Telegram:** `/api/webhook/telegram`
- **Discord:** `/api/webhook/discord`
- **Generic:** `/api/webhook/generic`

## 🎉 SUCCESS INDICATORS:
- ✅ N8N UI loads at port 5678
- ✅ Admin login works
- ✅ Workflows can be imported
- ✅ Webhook gateway responds
- ✅ End-to-end bot integration works
