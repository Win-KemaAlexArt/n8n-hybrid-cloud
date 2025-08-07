#!/usr/bin/env python3
"""
Oracle Cloud Always Free - Полная автоматизация создания инстанса и деплоя n8n
Использует Oracle Cloud CLI и Terraform для максимальной автоматизации
"""

import os
import subprocess
import json
import time
import requests
from pathlib import Path

class OracleCloudAutomation:
    def __init__(self):
        self.project_dir = Path(__file__).parent
        self.terraform_dir = self.project_dir / "terraform-oracle"
        
    def setup_oracle_cli(self):
        """Установка и настройка Oracle Cloud CLI"""
        print("🔧 Настраиваем Oracle Cloud CLI...")
        
        # Скачиваем и устанавливаем OCI CLI
        install_script = """
        curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh | bash
        """
        subprocess.run(install_script, shell=True, check=True)
        
        print("✅ Oracle CLI установлен")
        
    def create_terraform_config(self):
        """Создаем Terraform конфигурацию для Oracle Cloud"""
        self.terraform_dir.mkdir(exist_ok=True)
        
        # Main Terraform configuration
        terraform_main = '''
terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

provider "oci" {
  # Конфигурация будет взята из ~/.oci/config
}

# Always Free Compute Instance
resource "oci_core_instance" "n8n_instance" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_id
  display_name        = "n8n-hybrid-always-free"
  shape               = "VM.Standard.E2.1.Micro"  # Always Free eligible

  create_vnic_details {
    subnet_id        = oci_core_subnet.n8n_subnet.id
    display_name     = "n8n-vnic"
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_images.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file("~/.ssh/id_rsa.pub")
    user_data = base64encode(templatefile("${path.module}/user-data.sh", {
      supabase_url = var.supabase_url
      supabase_anon_key = var.supabase_anon_key
      telegram_bot_token = var.telegram_bot_token
      vercel_api_token = var.vercel_api_token
    }))
  }
}

# VCN (Virtual Cloud Network)
resource "oci_core_vcn" "n8n_vcn" {
  compartment_id = var.compartment_id
  cidr_block     = "10.1.0.0/16"
  display_name   = "n8n-vcn"
  dns_label      = "n8nvcn"
}

# Internet Gateway
resource "oci_core_internet_gateway" "n8n_internet_gateway" {
  compartment_id = var.compartment_id
  display_name   = "n8n-internet-gateway"
  vcn_id         = oci_core_vcn.n8n_vcn.id
}

# Route Table
resource "oci_core_default_route_table" "n8n_route_table" {
  manage_default_resource_id = oci_core_vcn.n8n_vcn.default_route_table_id
  display_name               = "n8n-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.n8n_internet_gateway.id
  }
}

# Subnet
resource "oci_core_subnet" "n8n_subnet" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  cidr_block          = "10.1.20.0/24"
  display_name        = "n8n-subnet"
  dns_label           = "n8nsubnet"
  security_list_ids   = [oci_core_security_list.n8n_security_list.id]
  compartment_id      = var.compartment_id
  vcn_id              = oci_core_vcn.n8n_vcn.id
  route_table_id      = oci_core_vcn.n8n_vcn.default_route_table_id
  dhcp_options_id     = oci_core_vcn.n8n_vcn.default_dhcp_options_id
}

# Security List
resource "oci_core_security_list" "n8n_security_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.n8n_vcn.id
  display_name   = "n8n-security-list"

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = "22"
      min = "22"
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = "80"
      min = "80"
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = "443"
      min = "443"
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = "5678"
      min = "5678"
    }
  }
}

# Data sources
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

data "oci_core_images" "ubuntu_images" {
  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Outputs
output "instance_public_ip" {
  value = oci_core_instance.n8n_instance.public_ip
}

output "instance_private_ip" {
  value = oci_core_instance.n8n_instance.private_ip
}

output "n8n_url" {
  value = "http://${oci_core_instance.n8n_instance.public_ip}"
}
'''
        
        with open(self.terraform_dir / "main.tf", "w") as f:
            f.write(terraform_main)
            
        # Variables
        variables = '''
variable "compartment_id" {
  description = "Oracle Cloud Compartment ID"
  type        = string
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
            
        # User data script
        user_data = '''#!/bin/bash
# Oracle Cloud Always Free - N8N Auto Installation
set -e

# Логирование
exec > >(tee /var/log/user-data.log) 2>&1

echo "🚀 Начинаем автоматическую установку N8N..."

# Обновляем систему
apt update && apt upgrade -y

# Устанавливаем зависимости
apt install -y curl wget git unzip

# Устанавливаем Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Устанавливаем Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Создаем проект
mkdir -p /home/ubuntu/n8n-hybrid
cd /home/ubuntu/n8n-hybrid

# Скачиваем конфигурацию из GitHub
git clone https://github.com/Win-KemaAlexArt/n8n-webhook-gateway.git .

# Создаем .env с переданными переменными
cat > .env << EOF
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=oracle_n8n_2025
N8N_ENCRYPTION_KEY=oracle_cloud_encryption_key_32chars
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=https
WEBHOOK_URL=https://$(curl -s ifconfig.me)

DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=oracle_postgres_password

SUPABASE_URL=${supabase_url}
SUPABASE_ANON_KEY=${supabase_anon_key}
TELEGRAM_BOT_TOKEN=${telegram_bot_token}
VERCEL_API_TOKEN=${vercel_api_token}
EOF

# Создаем упрощенный docker-compose
cat > docker-compose.yml << 'COMPOSE_EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: n8n
      POSTGRES_USER: n8n
      POSTGRES_PASSWORD: oracle_postgres_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    restart: unless-stopped

  n8n:
    image: n8nio/n8n:latest
    ports:
      - "80:5678"
      - "443:5678"
    environment:
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=oracle_n8n_2025
      - N8N_ENCRYPTION_KEY=oracle_cloud_encryption_key_32chars
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=oracle_postgres_password
      - QUEUE_BULL_REDIS_HOST=redis
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      - postgres
      - redis
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
  n8n_data:
COMPOSE_EOF

# Настраиваем права
chown -R ubuntu:ubuntu /home/ubuntu/n8n-hybrid

# Запускаем как пользователь ubuntu
sudo -u ubuntu docker-compose up -d

echo "✅ N8N успешно установлен!"
echo "🌐 URL: http://$(curl -s ifconfig.me)"
echo "🔐 Логин: admin / oracle_n8n_2025"
'''
        
        with open(self.terraform_dir / "user-data.sh", "w") as f:
            f.write(user_data)
            
        print("✅ Terraform конфигурация создана")
        
    def deploy_to_oracle(self):
        """Деплой на Oracle Cloud"""
        print("🚀 Запускаем деплой на Oracle Cloud Always Free...")
        
        os.chdir(self.terraform_dir)
        
        # Инициализация Terraform
        subprocess.run(["terraform", "init"], check=True)
        
        # Планирование
        subprocess.run(["terraform", "plan"], check=True)
        
        # Применение
        subprocess.run(["terraform", "apply", "-auto-approve"], check=True)
        
        # Получаем IP адрес
        result = subprocess.run(["terraform", "output", "-json"], 
                              capture_output=True, text=True, check=True)
        outputs = json.loads(result.stdout)
        
        public_ip = outputs["instance_public_ip"]["value"]
        n8n_url = outputs["n8n_url"]["value"]
        
        print(f"✅ Деплой завершен!")
        print(f"🌐 N8N URL: {n8n_url}")
        print(f"📍 Public IP: {public_ip}")
        print(f"🔐 Логин: admin / oracle_n8n_2025")
        
        return public_ip, n8n_url
        
    def wait_for_n8n(self, url, timeout=600):
        """Ждем запуска n8n"""
        print(f"⏳ Ждем запуска n8n на {url}...")
        
        start_time = time.time()
        while time.time() - start_time < timeout:
            try:
                response = requests.get(url, timeout=10)
                if response.status_code == 200:
                    print("✅ N8N запущен и доступен!")
                    return True
            except:
                pass
                
            time.sleep(30)
            print("⏳ Все еще ждем...")
            
        print("❌ Таймаут ожидания n8n")
        return False
        
    def run_full_automation(self):
        """Полная автоматизация"""
        try:
            print("🎯 ORACLE CLOUD ALWAYS FREE - ПОЛНАЯ АВТОМАТИЗАЦИЯ")
            print("=" * 60)
            
            # 1. Настройка CLI
            self.setup_oracle_cli()
            
            # 2. Создание Terraform конфигурации
            self.create_terraform_config()
            
            # 3. Деплой
            public_ip, n8n_url = self.deploy_to_oracle()
            
            # 4. Ожидание запуска
            if self.wait_for_n8n(n8n_url):
                print("🎉 СИСТЕМА ПОЛНОСТЬЮ ГОТОВА!")
                print(f"🌐 Доступ: {n8n_url}")
                print("📋 Следующие шаги:")
                print("1. Получи Service Role Key из Supabase")
                print("2. Импортируй workflows")
                print("3. Настрой credentials")
            
        except Exception as e:
            print(f"❌ Ошибка: {e}")
            return False
            
        return True

if __name__ == "__main__":
    automation = OracleCloudAutomation()
    automation.run_full_automation()
