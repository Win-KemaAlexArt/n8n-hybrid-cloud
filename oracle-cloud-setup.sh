#!/bin/bash
# Oracle Cloud Always Free - N8N Deployment Script
# Полностью автоматизированная установка n8n

set -e

echo "🚀 Начинаем установку N8N на Oracle Cloud Always Free..."

# Обновляем систему
sudo apt update && sudo apt upgrade -y

# Устанавливаем Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Устанавливаем Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Создаем директорию проекта
mkdir -p /home/ubuntu/n8n-hybrid
cd /home/ubuntu/n8n-hybrid

# Создаем .env файл
cat > .env << EOF
# N8N Configuration
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=n8n_oracle_2025
N8N_ENCRYPTION_KEY=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=https
WEBHOOK_URL=https://\${ORACLE_INSTANCE_IP}

# Database
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=n8n_oracle_password

# Supabase
SUPABASE_URL=https://nacpsvszdyabyuednbsg.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5hY3BzdnN6ZHlhYnl1ZWRuYnNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1MjAwNDMsImV4cCI6MjA3MDA5NjA0M30.-lo38TwmxnsoEzLSywM7Sz5kzy2vEfJU1Jc86AphvLo
SUPABASE_SERVICE_ROLE_KEY=ПОЛУЧИ_ИЗ_DASHBOARD

# Telegram Bot
TELEGRAM_BOT_TOKEN=8100032252:AAHo_x-IqAiQaVaNNBXdhVMfvT11brA9dLM

# Vercel
VERCEL_API_TOKEN=k3dQlIJIgMGed8jCNtjWdzEu
EOF

# Создаем docker-compose для Oracle Cloud
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: n8n-postgres
    environment:
      POSTGRES_DB: n8n
      POSTGRES_USER: n8n
      POSTGRES_PASSWORD: n8n_oracle_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U n8n"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    container_name: n8n-redis
    volumes:
      - redis_data:/data
    restart: unless-stopped

  n8n:
    image: n8nio/n8n:latest
    container_name: n8n-main
    ports:
      - "80:5678"
      - "443:5678"
    environment:
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=n8n_oracle_2025
      - N8N_ENCRYPTION_KEY=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=n8n_oracle_password
      - QUEUE_BULL_REDIS_HOST=redis
      - QUEUE_BULL_REDIS_PORT=6379
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
  n8n_data:
EOF

# Настраиваем firewall для Oracle Cloud
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 5678 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables/rules.v4

# Запускаем n8n
docker-compose up -d

echo "✅ N8N успешно установлен на Oracle Cloud!"
echo "🌐 Доступ: http://$(curl -s ifconfig.me)"
echo "🔐 Логин: admin"
echo "🔑 Пароль: n8n_oracle_2025"
echo ""
echo "📋 Следующие шаги:"
echo "1. Настрой Security List в Oracle Cloud для портов 80, 443"
echo "2. Получи Service Role Key из Supabase"
echo "3. Импортируй workflows"
echo ""
echo "🎉 Система готова к работе!"
