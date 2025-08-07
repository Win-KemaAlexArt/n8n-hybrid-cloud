#!/usr/bin/env node

// Скрипт для обновления конфигурации Supabase в проекте

const fs = require('fs');
const path = require('path');

class SupabaseConfigUpdater {
  constructor() {
    this.configPath = path.join(__dirname, '../supabase-config.json');
    this.vercelEnvPath = path.join(__dirname, '../vercel-webhook-gateway/.env.local');
  }

  updateConfig() {
    console.log('🔧 Обновление конфигурации Supabase...');
    
    try {
      // Чтение конфигурации Supabase
      const config = JSON.parse(fs.readFileSync(this.configPath, 'utf8'));
      
      if (config.project_url === 'ВСТАВЬ_СЮДА_PROJECT_URL') {
        console.log('❌ Сначала обновите supabase-config.json с реальными данными!');
        console.log('📋 Инструкция:');
        console.log('1. Откройте supabase-config.json');
        console.log('2. Замените все ВСТАВЬ_СЮДА_* на реальные значения из Supabase');
        console.log('3. Запустите скрипт снова');
        return;
      }

      // Создание .env.local для Vercel
      const envContent = `# Supabase Configuration
SUPABASE_URL=${config.project_url}
SUPABASE_ANON_KEY=${config.anon_key}
SUPABASE_SERVICE_ROLE_KEY=${config.service_role_key}

# AWS Configuration (обновите после развертывания AWS)
AWS_N8N_ENDPOINT=https://your-ec2-ip:5678

# Telegram Bot (получите от @BotFather)
TELEGRAM_BOT_TOKEN=your_telegram_bot_token
`;

      fs.writeFileSync(this.vercelEnvPath, envContent);
      
      // Обновление credentials.json
      const credentialsPath = path.join(__dirname, '../credentials.json');
      let credentials = {};
      
      if (fs.existsSync(credentialsPath)) {
        credentials = JSON.parse(fs.readFileSync(credentialsPath, 'utf8'));
      }
      
      credentials.supabase = {
        project_url: config.project_url,
        anon_key: config.anon_key,
        service_role_key: config.service_role_key,
        database_password: config.database_password,
        updated_at: new Date().toISOString()
      };
      
      fs.writeFileSync(credentialsPath, JSON.stringify(credentials, null, 2));
      
      console.log('✅ Конфигурация Supabase обновлена!');
      console.log('📁 Файлы обновлены:');
      console.log('  - .env.local (для Vercel)');
      console.log('  - credentials.json (общая конфигурация)');
      console.log('');
      console.log('🚀 Следующие шаги:');
      console.log('1. Разверните Vercel проект: cd vercel-webhook-gateway && vercel --prod');
      console.log('2. Настройте переменные окружения в Vercel Dashboard');
      console.log('3. Запустите AWS развертывание: bash aws-infrastructure/deploy-aws.sh');
      
    } catch (error) {
      console.error('❌ Ошибка обновления конфигурации:', error.message);
    }
  }

  testConnection() {
    console.log('🧪 Тестирование подключения к Supabase...');
    
    try {
      const config = JSON.parse(fs.readFileSync(this.configPath, 'utf8'));
      
      if (config.project_url === 'ВСТАВЬ_СЮДА_PROJECT_URL') {
        console.log('❌ Сначала настройте supabase-config.json');
        return;
      }
      
      // Простой тест подключения
      const testScript = `
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient('${config.project_url}', '${config.anon_key}');

async function testConnection() {
  try {
    const { data, error } = await supabase
      .from('workflow_analytics')
      .select('count')
      .limit(1);
    
    if (error && error.code !== 'PGRST116') {
      console.log('❌ Ошибка подключения:', error.message);
    } else {
      console.log('✅ Подключение к Supabase успешно!');
    }
  } catch (err) {
    console.log('❌ Ошибка:', err.message);
  }
}

testConnection();
      `;
      
      fs.writeFileSync(path.join(__dirname, 'test-supabase.js'), testScript);
      console.log('📝 Тест создан: automation-scripts/test-supabase.js');
      console.log('🚀 Запустите: node automation-scripts/test-supabase.js');
      
    } catch (error) {
      console.error('❌ Ошибка создания теста:', error.message);
    }
  }
}

// Запуск
if (require.main === module) {
  const updater = new SupabaseConfigUpdater();
  
  const command = process.argv[2];
  if (command === 'test') {
    updater.testConnection();
  } else {
    updater.updateConfig();
  }
}

module.exports = SupabaseConfigUpdater;
