#!/bin/bash

# EC2 User Data Script для автоматической установки n8n
# Выполняется при первом запуске инстанса

# Обновление системы
apt-get update -y
apt-get upgrade -y

# Установка Docker
apt-get install -y docker.io docker-compose-plugin
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Установка Node.js (для дополнительных инструментов)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Установка AWS CLI
apt-get install -y awscli

# Установка Nginx
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx

# Создание директории для n8n
mkdir -p /opt/n8n
cd /opt/n8n

# Создание docker-compose.yml для n8n
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    ports:
      - "5678:5678"
    environment:
      # Базовая конфигурация
      N8N_HOST: "0.0.0.0"
      N8N_PORT: 5678
      N8N_PROTOCOL: http
      WEBHOOK_URL: "http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5678/"
      
      # Оптимизация для 1GB RAM
      N8N_LOG_LEVEL: warn
      EXECUTIONS_DATA_PRUNE: true
      EXECUTIONS_DATA_MAX_AGE: 168  # 7 дней
      EXECUTIONS_PROCESS: main
      
      # Безопасность
      N8N_BASIC_AUTH_ACTIVE: true
      N8N_BASIC_AUTH_USER: admin
      N8N_BASIC_AUTH_PASSWORD: n8n_secure_password_2025
      
      # Персистентность данных
      N8N_USER_FOLDER: /home/node/.n8n
      
    volumes:
      - n8n_data:/home/node/.n8n
      - /var/run/docker.sock:/var/run/docker.sock:ro
    restart: unless-stopped
    
  # Nginx прокси для SSL и кеширования
  nginx:
    image: nginx:alpine
    container_name: n8n-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - n8n
    restart: unless-stopped

volumes:
  n8n_data:
    driver: local
EOF

# Создание конфигурации Nginx
cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream n8n {
        server n8n:5678;
    }
    
    # Кеширование статических ресурсов
    proxy_cache_path /tmp/nginx_cache levels=1:2 keys_zone=n8n_cache:10m max_size=100m inactive=60m use_temp_path=off;
    
    server {
        listen 80;
        server_name _;
        
        # Редирект на HTTPS (когда SSL будет настроен)
        # return 301 https://$server_name$request_uri;
        
        # Временно работаем по HTTP
        location / {
            proxy_pass http://n8n;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # WebSocket поддержка
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            
            # Таймауты
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }
        
        # Кеширование статики
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            proxy_pass http://n8n;
            proxy_cache n8n_cache;
            proxy_cache_valid 200 1h;
            proxy_cache_use_stale error timeout invalid_header updating http_500 http_502 http_503 http_504;
            add_header X-Cache-Status $upstream_cache_status;
        }
    }
}
EOF

# Создание SSL директории (для будущего использования)
mkdir -p ssl

# Запуск n8n
docker compose up -d

# Создание systemd сервиса для автозапуска
cat > /etc/systemd/system/n8n.service << 'EOF'
[Unit]
Description=n8n workflow automation
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/n8n
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Включение автозапуска
systemctl enable n8n.service

# Создание скрипта для обновления RDS конфигурации
cat > update-rds-config.sh << 'EOF'
#!/bin/bash

# Скрипт для обновления конфигурации RDS после создания базы данных
# Запускается после получения RDS endpoint

RDS_ENDPOINT=$1
DB_USERNAME=$2
DB_PASSWORD=$3

if [ -z "$RDS_ENDPOINT" ] || [ -z "$DB_USERNAME" ] || [ -z "$DB_PASSWORD" ]; then
    echo "Использование: $0 <RDS_ENDPOINT> <DB_USERNAME> <DB_PASSWORD>"
    exit 1
fi

# Обновление docker-compose.yml с RDS конфигурацией
cat > docker-compose.yml << EOF
version: '3.8'
services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    ports:
      - "5678:5678"
    environment:
      # База данных RDS PostgreSQL
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: $RDS_ENDPOINT
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: n8n
      DB_POSTGRESDB_USER: $DB_USERNAME
      DB_POSTGRESDB_PASSWORD: $DB_PASSWORD
      DB_POSTGRESDB_SCHEMA: public
      
      # Базовая конфигурация
      N8N_HOST: "0.0.0.0"
      N8N_PORT: 5678
      N8N_PROTOCOL: http
      WEBHOOK_URL: "http://\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5678/"
      
      # Оптимизация для 1GB RAM
      N8N_LOG_LEVEL: warn
      EXECUTIONS_DATA_PRUNE: true
      EXECUTIONS_DATA_MAX_AGE: 168
      EXECUTIONS_PROCESS: main
      
      # Безопасность
      N8N_BASIC_AUTH_ACTIVE: true
      N8N_BASIC_AUTH_USER: admin
      N8N_BASIC_AUTH_PASSWORD: n8n_secure_password_2025
      
    volumes:
      - n8n_data:/home/node/.n8n
      - /var/run/docker.sock:/var/run/docker.sock:ro
    restart: unless-stopped
    
  nginx:
    image: nginx:alpine
    container_name: n8n-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - n8n
    restart: unless-stopped

volumes:
  n8n_data:
    driver: local
EOF

# Перезапуск с новой конфигурацией
docker compose down
docker compose up -d

echo "✅ n8n обновлен для работы с RDS PostgreSQL"
EOF

chmod +x update-rds-config.sh

# Логирование установки
echo "$(date): n8n installation completed" >> /var/log/n8n-install.log
echo "n8n доступен по адресу: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5678" >> /var/log/n8n-install.log
echo "Логин: admin, Пароль: n8n_secure_password_2025" >> /var/log/n8n-install.log
