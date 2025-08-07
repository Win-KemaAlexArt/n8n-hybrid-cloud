# 🚀 N8N Гибридная Экосистема

## 📋 Обзор Проекта

Полностью автоматизированная система развертывания n8n workflows с использованием гибридной облачной архитектуры:

- **AWS EC2 + RDS** - основная обработка n8n workflows
- **Vercel Edge Functions** - быстрые webhook обработчики  
- **Supabase** - аналитика и хранение данных
- **GitHub** - CI/CD и версионирование

## 🏗️ Архитектура

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Vercel Edge   │    │    AWS EC2       │    │   Supabase      │
│   Functions     │────│   n8n Instance   │────│   Analytics     │
│  (Webhooks)     │    │   + RDS Postgres │    │   + Storage     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 📁 Структура Проекта

```
n8n/
├── automation-scripts/     # Скрипты автоматизации
├── aws-infrastructure/     # AWS деплой конфигурация
├── n8n-webhook-gateway/    # Next.js webhook gateway
├── vercel-webhook-gateway/ # Альтернативный gateway
├── supabase-integration/   # SQL схемы и setup
├── mcp-vercel/            # MCP сервер для Vercel
├── credentials.json       # Учетные данные
└── supabase-config.json   # Конфигурация Supabase
```

## 🚀 Быстрый Старт

### 1. Развертывание Vercel Gateway
```bash
cd n8n-webhook-gateway
npm install
vercel --prod
```

### 2. Настройка AWS Infrastructure
```bash
cd aws-infrastructure
chmod +x deploy-aws.sh
./deploy-aws.sh
```

### 3. Инициализация Supabase
```bash
cd supabase-integration
node setup-supabase.js
```

## 🔧 Конфигурация

### Переменные Окружения
```env
# Vercel
VERCEL_API_TOKEN=k3dQlIJIgMGed8jCNtjWdzEu

# Supabase
SUPABASE_ACCESS_TOKEN=sbp_4262f5785f8f024c2377ccf952b9336f64ee09d1
SUPABASE_PROJECT_REF=nacpsvszdyabyuednbsg

# AWS (настроить)
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
```

## 📊 Мониторинг

- **Vercel Dashboard:** Статистика webhook'ов
- **Supabase Dashboard:** Аналитика workflows  
- **AWS CloudWatch:** Мониторинг EC2 и RDS

## 🛠️ MCP Интеграция

Настроены MCP серверы для Windsurf AI:
- **Vercel MCP:** Управление деплоями
- **Supabase MCP:** Управление БД

## 📈 Масштабирование

1. **Vercel:** Hobby → Pro ($20/мес)
2. **AWS:** t2.micro → t3.small ($15/мес)  
3. **Supabase:** Free → Pro ($25/мес)

## 🔐 Безопасность

- Все API ключи в переменных окружения
- Read-only режим для MCP серверов
- Приватный GitHub репозиторий

## 📞 Поддержка

Проект полностью автоматизирован с уровнем детализации **1000000⁹*⁹*⁹↑/000.1**
