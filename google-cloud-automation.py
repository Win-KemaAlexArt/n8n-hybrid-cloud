#!/usr/bin/env python3
"""
Google Cloud Always Free - Автоматизация деплоя n8n
f1-micro instance - БЕСРОЧНО БЕСПЛАТНО
"""

import os
import subprocess
import json
import time
from pathlib import Path

class GoogleCloudAutomation:
    def __init__(self):
        self.project_dir = Path(__file__).parent
        self.terraform_dir = self.project_dir / "terraform-gcp"
        
    def setup_gcloud_cli(self):
        """Установка Google Cloud CLI"""
        print("🔧 Настраиваем Google Cloud CLI...")
        
        # Скачиваем и устанавливаем gcloud CLI
        install_script = """
        curl https://sdk.cloud.google.com | bash
        exec -l $SHELL
        gcloud init
        """
        print("📋 Выполни команды:")
        print(install_script)
        print("✅ После установки запусти: gcloud auth login")
        
    def create_terraform_config(self):
        """Создаем Terraform для Google Cloud"""
        self.terraform_dir.mkdir(exist_ok=True)
        
        # Main Terraform configuration
        terraform_main = '''
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Always Free f1-micro instance
resource "google_compute_instance" "n8n_instance" {
  name         = "n8n-hybrid-always-free"
  machine_type = "f1-micro"  # Always Free eligible
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30  # GB - Always Free limit
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  metadata_startup_script = templatefile("${path.module}/startup-script.sh", {
    supabase_url = var.supabase_url
    supabase_anon_key = var.supabase_anon_key
    telegram_bot_token = var.telegram_bot_token
    vercel_api_token = var.vercel_api_token
  })

  tags = ["n8n-server", "http-server", "https-server"]

  service_account {
    scopes = ["cloud-platform"]
  }
}

# Firewall rules
resource "google_compute_firewall" "n8n_firewall" {
  name    = "n8n-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "5678"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["n8n-server"]
}

# Outputs
output "instance_external_ip" {
  value = google_compute_instance.n8n_instance.network_interface[0].access_config[0].nat_ip
}

output "instance_internal_ip" {
  value = google_compute_instance.n8n_instance.network_interface[0].network_ip
}

output "n8n_url" {
  value = "http://${google_compute_instance.n8n_instance.network_interface[0].access_config[0].nat_ip}"
}

output "ssh_command" {
  value = "ssh -i ${var.ssh_private_key_path} ${var.ssh_user}@${google_compute_instance.n8n_instance.network_interface[0].access_config[0].nat_ip}"
}
'''
        
        with open(self.terraform_dir / "main.tf", "w") as f:
            f.write(terraform_main)
            
        # Variables
        variables = '''
variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud Region"
  type        = string
  default     = "us-central1"  # Always Free eligible
}

variable "zone" {
  description = "Google Cloud Zone"
  type        = string
  default     = "us-central1-a"  # Always Free eligible
}

variable "ssh_user" {
  description = "SSH Username"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "supabase_url" {
  description = "Supabase Project URL"
  type        = string
  default     = "https://nacpsvszdyabyuednbsg.supabase.co"
}

variable "supabase_anon_key" {
  description = "Supabase Anonymous Key"
  type        = string
  default     = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5hY3BzdnN6ZHlhYnl1ZWRuYnNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1MjAwNDMsImV4cCI6MjA3MDA5NjA0M30.-lo38TwmxnsoEzLSywM7Sz5kzy2vEfJU1Jc86AphvLo"
}

variable "telegram_bot_token" {
  description = "Telegram Bot Token"
  type        = string
  default     = "8100032252:AAHo_x-IqAiQaVaNNBXdhVMfvT11brA9dLM"
}

variable "vercel_api_token" {
  description = "Vercel API Token"
  type        = string
  default     = "k3dQlIJIgMGed8jCNtjWdzEu"
}
'''
        
        with open(self.terraform_dir / "variables.tf", "w") as f:
            f.write(variables)
            
        # Startup script
        startup_script = '''#!/bin/bash
# Google Cloud f1-micro - N8N Auto Installation
set -e

# Логирование
exec > >(tee /var/log/startup-script.log) 2>&1

echo "🚀 Начинаем установку N8N на Google Cloud f1-micro..."

# Обновляем систему
apt update && apt upgrade -y

# Устанавливаем зависимости
apt install -y curl wget git unzip htop

# Устанавливаем Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Устанавливаем Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Создаем swap для f1-micro (0.6GB RAM)
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

# Создаем проект
mkdir -p /home/ubuntu/n8n-hybrid
cd /home/ubuntu/n8n-hybrid

# Создаем оптимизированный docker-compose для f1-micro
cat > docker-compose.yml << 'COMPOSE_EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: n8n-postgres
    environment:
      POSTGRES_DB: n8n
      POSTGRES_USER: n8n
      POSTGRES_PASSWORD: gcp_postgres_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 128M
        reservations:
          memory: 64M

  redis:
    image: redis:7-alpine
    container_name: n8n-redis
    volumes:
      - redis_data:/data
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 64M
        reservations:
          memory: 32M

  n8n:
    image: n8nio/n8n:latest
    container_name: n8n-main
    ports:
      - "80:5678"
      - "443:5678"
    environment:
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=gcp_n8n_2025
      - N8N_ENCRYPTION_KEY=gcp_cloud_encryption_key_32_chars
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=gcp_postgres_password
      - QUEUE_BULL_REDIS_HOST=redis
      - N8N_METRICS=true
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      - postgres
      - redis
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 384M
        reservations:
          memory: 256M

volumes:
  postgres_data:
  redis_data:
  n8n_data:
COMPOSE_EOF

# Создаем .env
cat > .env << EOF
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=gcp_n8n_2025
N8N_ENCRYPTION_KEY=gcp_cloud_encryption_key_32_chars
SUPABASE_URL=${supabase_url}
SUPABASE_ANON_KEY=${supabase_anon_key}
TELEGRAM_BOT_TOKEN=${telegram_bot_token}
VERCEL_API_TOKEN=${vercel_api_token}
EOF

# Настраиваем права
chown -R ubuntu:ubuntu /home/ubuntu/n8n-hybrid

# Запускаем
sudo -u ubuntu docker-compose up -d

echo "✅ N8N установлен на Google Cloud f1-micro!"
echo "🌐 URL: http://$(curl -s ifconfig.me)"
echo "🔐 Логин: admin / gcp_n8n_2025"
echo "💾 RAM: 0.6GB + 2GB swap"
'''
        
        with open(self.terraform_dir / "startup-script.sh", "w") as f:
            f.write(startup_script)
            
        print("✅ Google Cloud Terraform конфигурация создана")

if __name__ == "__main__":
    automation = GoogleCloudAutomation()
    automation.setup_gcloud_cli()
    automation.create_terraform_config()
    print("🎯 Конфигурация готова! Следуй инструкциям в GOOGLE_CLOUD_SETUP.md")
