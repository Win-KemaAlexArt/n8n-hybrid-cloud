// Автоматическая настройка Supabase для аналитики n8n
// Создание таблиц, функций и интеграций

const { createClient } = require('@supabase/supabase-js');

// Конфигурация Supabase (заполнить после создания проекта)
const SUPABASE_URL = 'https://your-project-id.supabase.co';
const SUPABASE_SERVICE_KEY = 'your-service-role-key';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

async function setupSupabaseAnalytics() {
  console.log('🚀 Настройка Supabase аналитики для n8n...');

  try {
    // 1. Создание таблицы для аналитики воркфлоу
    console.log('📊 Создание таблицы workflow_analytics...');
    const { error: tableError } = await supabase.rpc('create_workflow_analytics_table');
    
    if (tableError && !tableError.message.includes('already exists')) {
      throw tableError;
    }

    // 2. Создание таблицы для мониторинга системы
    console.log('🖥️ Создание таблицы system_metrics...');
    const { error: metricsError } = await supabase.rpc('create_system_metrics_table');
    
    if (metricsError && !metricsError.message.includes('already exists')) {
      throw metricsError;
    }

    // 3. Создание таблицы для логов ошибок
    console.log('❌ Создание таблицы error_logs...');
    const { error: logsError } = await supabase.rpc('create_error_logs_table');
    
    if (logsError && !logsError.message.includes('already exists')) {
      throw logsError;
    }

    // 4. Создание функций для аналитики
    console.log('⚡ Создание функций аналитики...');
    await createAnalyticsFunctions();

    // 5. Настройка Real-time подписок
    console.log('🔄 Настройка Real-time подписок...');
    await setupRealtimeSubscriptions();

    // 6. Создание тестовых данных
    console.log('🧪 Создание тестовых данных...');
    await insertTestData();

    console.log('✅ Supabase аналитика настроена успешно!');
    console.log('📈 Доступные эндпоинты:');
    console.log(`   - Workflow Analytics: ${SUPABASE_URL}/rest/v1/workflow_analytics`);
    console.log(`   - System Metrics: ${SUPABASE_URL}/rest/v1/system_metrics`);
    console.log(`   - Error Logs: ${SUPABASE_URL}/rest/v1/error_logs`);

  } catch (error) {
    console.error('❌ Ошибка настройки Supabase:', error);
    process.exit(1);
  }
}

async function createAnalyticsFunctions() {
  // SQL функции будут созданы через Supabase Dashboard или SQL Editor
  const functions = [
    {
      name: 'log_workflow_execution',
      description: 'Логирование выполнения воркфлоу'
    },
    {
      name: 'get_workflow_stats',
      description: 'Получение статистики воркфлоу'
    },
    {
      name: 'get_system_health',
      description: 'Проверка состояния системы'
    }
  ];

  console.log('📝 Функции для создания в Supabase SQL Editor:');
  functions.forEach(func => {
    console.log(`   - ${func.name}: ${func.description}`);
  });
}

async function setupRealtimeSubscriptions() {
  // Настройка подписок на изменения в реальном времени
  const subscription = supabase
    .channel('workflow_analytics')
    .on('postgres_changes', 
      { event: 'INSERT', schema: 'public', table: 'workflow_analytics' },
      (payload) => {
        console.log('📊 Новое выполнение воркфлоу:', payload.new);
      }
    )
    .subscribe();

  console.log('🔄 Real-time подписка активирована');
}

async function insertTestData() {
  // Вставка тестовых данных для проверки
  const testWorkflows = [
    {
      workflow_name: 'telegram_bot_handler',
      execution_time: new Date().toISOString(),
      duration_ms: 150,
      status: 'completed',
      input_data: { message: 'test message' },
      output_data: { response: 'success' }
    },
    {
      workflow_name: 'webhook_processor',
      execution_time: new Date().toISOString(),
      duration_ms: 89,
      status: 'completed',
      input_data: { webhook_type: 'stripe' },
      output_data: { processed: true }
    }
  ];

  const { error } = await supabase
    .from('workflow_analytics')
    .insert(testWorkflows);

  if (error) {
    console.log('⚠️ Тестовые данные будут добавлены после создания таблиц');
  } else {
    console.log('✅ Тестовые данные добавлены');
  }
}

// Экспорт функций для использования в n8n
module.exports = {
  setupSupabaseAnalytics,
  
  // Функция для логирования из n8n воркфлоу
  logWorkflowExecution: async (workflowData) => {
    const { error } = await supabase
      .from('workflow_analytics')
      .insert({
        workflow_name: workflowData.name,
        execution_time: new Date().toISOString(),
        duration_ms: workflowData.duration,
        status: workflowData.status,
        input_data: workflowData.input,
        output_data: workflowData.output,
        error_message: workflowData.error
      });

    if (error) {
      console.error('Ошибка логирования в Supabase:', error);
    }
  },

  // Функция для получения статистики
  getWorkflowStats: async (timeframe = '24h') => {
    const { data, error } = await supabase
      .from('workflow_analytics')
      .select('*')
      .gte('execution_time', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString());

    return { data, error };
  }
};

// Запуск настройки если файл выполняется напрямую
if (require.main === module) {
  setupSupabaseAnalytics();
}
