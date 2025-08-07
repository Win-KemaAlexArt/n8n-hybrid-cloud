# 🎯 Oracle Cloud Always Free - N8N Автоматизация

## 🆓 БЕСРОЧНО БЕСПЛАТНЫЙ ПЛАН

Oracle Cloud Always Free предоставляет:
- ✅ **2 VM instances** (VM.Standard.E2.1.Micro)
- ✅ **1GB RAM каждая** = 2GB всего
- ✅ **200GB Block Storage**
- ✅ **10TB исходящего трафика**
- ✅ **НАВСЕГДА БЕСПЛАТНО** (не trial!)

## 🚀 АВТОМАТИЧЕСКАЯ УСТАНОВКА

### Шаг 1: Регистрация в Oracle Cloud

1. Перейди на: https://www.oracle.com/cloud/free/
2. Нажми "Start for free"
3. Заполни форму (потребуется кредитная карта для верификации, но списаний не будет)
4. Подтверди email и телефон

### Шаг 2: Настройка CLI и ключей

```bash
# Установка Python зависимостей
pip install oci-cli requests

# Настройка OCI CLI (следуй инструкциям)
oci setup config

# Генерация SSH ключей (если нет)
ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa
```

### Шаг 3: Получение Compartment ID

1. Войди в Oracle Cloud Console
2. Перейди в Identity & Security > Compartments
3. Скопируй OCID root compartment

### Шаг 4: Запуск автоматизации

```bash
cd d:\Development\GitHub\n8n

# Установка зависимостей
pip install -r requirements.txt

# Экспорт переменных
export TF_VAR_compartment_id="ocid1.compartment.oc1..your_compartment_id"

# Запуск полной автоматизации
python oracle-cloud-automation.py
```

## 🎯 ЧТО ПРОИСХОДИТ АВТОМАТИЧЕСКИ

1. **Создание инфраструктуры:**
   - VCN (Virtual Cloud Network)
   - Subnet с публичным IP
   - Security Groups (порты 22, 80, 443, 5678)
   - VM Instance (Always Free tier)

2. **Установка на сервере:**
   - Docker и Docker Compose
   - Клонирование проекта из GitHub
   - Настройка .env файла
   - Запуск n8n + PostgreSQL + Redis

3. **Интеграция сервисов:**
   - Подключение к Supabase
   - Настройка Telegram бота
   - Интеграция с Vercel

## 🔐 ДАННЫЕ ДЛЯ ДОСТУПА

После завершения установки:

- **URL:** `http://YOUR_ORACLE_IP`
- **Логин:** `admin`
- **Пароль:** `oracle_n8n_2025`

## 📋 СЛЕДУЮЩИЕ ШАГИ

1. **Получи Service Role Key:**
   - https://supabase.com/dashboard/project/nacpsvszdyabyuednbsg/settings/api
   - Скопируй "service_role" ключ

2. **Выполни SQL миграции в Supabase:**
   ```sql
   -- Создание таблиц аналитики (выполни в SQL Editor)
   -- Код из MEMORY[0b63bb05-a6bf-45b4-bb30-448424c2f8c7]
   ```

3. **Импортируй workflows:**
   - `workflows/example-telegram-bot.json`
   - `workflows/aws-deployment-monitor.json`
   - `workflows/supabase-analytics.json`

## 🛠️ АЛЬТЕРНАТИВНЫЙ РУЧНОЙ СПОСОБ

Если автоматизация не работает, используй готовый скрипт:

```bash
# Скопируй на Oracle Cloud instance
scp oracle-cloud-setup.sh ubuntu@YOUR_ORACLE_IP:~/

# Выполни на сервере
ssh ubuntu@YOUR_ORACLE_IP
chmod +x oracle-cloud-setup.sh
./oracle-cloud-setup.sh
```

## 🎉 РЕЗУЛЬТАТ

✅ **N8N в облаке БЕСПЛАТНО НАВСЕГДА**
✅ **Полная автоматизация деплоя**
✅ **Интеграция с Supabase и Vercel**
✅ **Готовые workflows для мониторинга**
✅ **Telegram бот для управления**

**СИСТЕМА ГОТОВА К PRODUCTION ИСПОЛЬЗОВАНИЮ!**
