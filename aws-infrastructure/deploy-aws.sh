#!/bin/bash

# AWS n8n Infrastructure Deployment Script
# Автоматическое создание EC2 + RDS для n8n

echo "🚀 Начинаем развертывание AWS инфраструктуры для n8n..."

# Переменные конфигурации
AWS_REGION="us-east-1"
KEY_NAME="n8n-key"
INSTANCE_TYPE="t2.micro"
DB_INSTANCE_CLASS="db.t2.micro"
DB_NAME="n8n"
DB_USERNAME="n8n_user"
DB_PASSWORD="$(openssl rand -base64 32)"

# 1. Создание Key Pair
echo "🔑 Создание SSH ключа..."
aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --query 'KeyMaterial' \
    --output text > ~/.ssh/${KEY_NAME}.pem
chmod 400 ~/.ssh/${KEY_NAME}.pem

# 2. Создание Security Group для EC2
echo "🛡️ Создание Security Group для EC2..."
EC2_SG_ID=$(aws ec2 create-security-group \
    --group-name n8n-ec2-sg \
    --description "Security group for n8n EC2 instance" \
    --query 'GroupId' \
    --output text)

# Открытие портов для EC2
aws ec2 authorize-security-group-ingress \
    --group-id $EC2_SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id $EC2_SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id $EC2_SG_ID \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id $EC2_SG_ID \
    --protocol tcp \
    --port 5678 \
    --cidr 0.0.0.0/0

# 3. Создание Security Group для RDS
echo "🗄️ Создание Security Group для RDS..."
RDS_SG_ID=$(aws ec2 create-security-group \
    --group-name n8n-rds-sg \
    --description "Security group for n8n RDS instance" \
    --query 'GroupId' \
    --output text)

# Разрешение доступа к PostgreSQL от EC2
aws ec2 authorize-security-group-ingress \
    --group-id $RDS_SG_ID \
    --protocol tcp \
    --port 5432 \
    --source-group $EC2_SG_ID

# 4. Создание RDS PostgreSQL
echo "🐘 Создание RDS PostgreSQL..."
aws rds create-db-instance \
    --db-instance-identifier n8n-postgres \
    --db-instance-class $DB_INSTANCE_CLASS \
    --engine postgres \
    --engine-version 15.4 \
    --master-username $DB_USERNAME \
    --master-user-password $DB_PASSWORD \
    --allocated-storage 20 \
    --vpc-security-group-ids $RDS_SG_ID \
    --publicly-accessible \
    --backup-retention-period 7 \
    --storage-encrypted

echo "⏳ Ожидание готовности RDS (это может занять 10-15 минут)..."
aws rds wait db-instance-available --db-instance-identifier n8n-postgres

# Получение endpoint RDS
RDS_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier n8n-postgres \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

# 5. Создание EC2 инстанса
echo "💻 Создание EC2 инстанса..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-0c02fb55956c7d316 \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $EC2_SG_ID \
    --user-data file://user-data.sh \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "⏳ Ожидание запуска EC2..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Получение публичного IP
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

# 6. Сохранение конфигурации
cat > aws-config.json << EOF
{
  "aws_region": "$AWS_REGION",
  "ec2_instance_id": "$INSTANCE_ID",
  "ec2_public_ip": "$PUBLIC_IP",
  "ec2_security_group": "$EC2_SG_ID",
  "rds_endpoint": "$RDS_ENDPOINT",
  "rds_security_group": "$RDS_SG_ID",
  "db_name": "$DB_NAME",
  "db_username": "$DB_USERNAME",
  "db_password": "$DB_PASSWORD",
  "ssh_key_path": "~/.ssh/${KEY_NAME}.pem"
}
EOF

echo "✅ AWS инфраструктура создана успешно!"
echo "🖥️ EC2 Public IP: $PUBLIC_IP"
echo "🗄️ RDS Endpoint: $RDS_ENDPOINT"
echo "🔑 SSH подключение: ssh -i ~/.ssh/${KEY_NAME}.pem ubuntu@$PUBLIC_IP"
echo "📋 Конфигурация сохранена в aws-config.json"
