// Vercel Edge Function для обработки Telegram webhook'ов
// Быстрая обработка простых команд + делегирование сложных задач в AWS n8n

export default async function handler(req, res) {
  // Проверка метода запроса
  if (req.method !== 'POST') {
    return res.status(405).json({ 
      error: 'Method not allowed',
      allowed: ['POST'] 
    });
  }

  try {
    const { message, callback_query } = req.body;
    
    // Логирование входящего запроса
    console.log('📨 Incoming Telegram webhook:', {
      messageId: message?.message_id,
      chatId: message?.chat?.id,
      text: message?.text,
      callbackData: callback_query?.data
    });

    // Обработка обычных сообщений
    if (message) {
      return await handleMessage(message, res);
    }
    
    // Обработка callback кнопок
    if (callback_query) {
      return await handleCallbackQuery(callback_query, res);
    }

    return res.status(200).json({ ok: true, message: 'No action required' });

  } catch (error) {
    console.error('❌ Telegram webhook error:', error);
    
    // Логирование ошибки в Supabase
    await logError('telegram_webhook', error.message, req.body);
    
    return res.status(500).json({ 
      error: 'Internal server error',
      timestamp: new Date().toISOString()
    });
  }
}

async function handleMessage(message, res) {
  const { text, chat } = message;
  const chatId = chat.id;

  // Быстрые команды (обрабатываются на Vercel Edge)
  const quickCommands = {
    '/start': async () => {
      await sendTelegramMessage(chatId, 
        '🚀 Привет! Я готов к работе.\n\n' +
        'Доступные команды:\n' +
        '/help - Помощь\n' +
        '/status - Статус системы\n' +
        '/stats - Статистика\n' +
        '/complex - Сложные операции'
      );
      return { processed: 'quick', command: '/start' };
    },

    '/help': async () => {
      await sendTelegramMessage(chatId,
        '📖 Справка по командам:\n\n' +
        '⚡ Быстрые команды (Edge):\n' +
        '/start - Приветствие\n' +
        '/help - Эта справка\n' +
        '/status - Статус системы\n\n' +
        '🔧 Сложные команды (AWS n8n):\n' +
        '/complex - Комплексная обработка\n' +
        '/workflow - Запуск воркфлоу\n' +
        '/analytics - Аналитика'
      );
      return { processed: 'quick', command: '/help' };
    },

    '/status': async () => {
      const status = await getSystemStatus();
      await sendTelegramMessage(chatId,
        `🖥️ Статус системы:\n\n` +
        `Vercel Edge: ✅ Активен\n` +
        `AWS n8n: ${status.aws_n8n ? '✅' : '❌'} ${status.aws_n8n ? 'Активен' : 'Недоступен'}\n` +
        `Supabase: ${status.supabase ? '✅' : '❌'} ${status.supabase ? 'Активен' : 'Недоступен'}\n` +
        `Время ответа: ${Date.now() - status.startTime}ms`
      );
      return { processed: 'quick', command: '/status' };
    }
  };

  // Проверка на быструю команду
  if (quickCommands[text]) {
    const result = await quickCommands[text]();
    await logWorkflowExecution('telegram_quick_command', result, 'completed');
    return res.status(200).json({ ok: true, ...result });
  }

  // Сложные команды отправляем в AWS n8n
  if (text?.startsWith('/complex') || text?.startsWith('/workflow') || text?.startsWith('/analytics')) {
    return await delegateToAWS(message, res);
  }

  // Обычные сообщения тоже отправляем в AWS для обработки
  if (text && !text.startsWith('/')) {
    return await delegateToAWS(message, res);
  }

  // Неизвестная команда
  await sendTelegramMessage(chatId, 
    '❓ Неизвестная команда. Используйте /help для получения справки.'
  );
  
  return res.status(200).json({ ok: true, processed: 'unknown_command' });
}

async function handleCallbackQuery(callbackQuery, res) {
  const { data, message } = callbackQuery;
  const chatId = message.chat.id;

  // Быстрые callback'и
  const quickCallbacks = {
    'status': async () => {
      const status = await getSystemStatus();
      return await sendTelegramMessage(chatId, `System status: ${JSON.stringify(status)}`);
    },
    'help': async () => {
      return await sendTelegramMessage(chatId, 'Quick help from Edge Function');
    }
  };

  if (quickCallbacks[data]) {
    await quickCallbacks[data]();
    return res.status(200).json({ ok: true, processed: 'quick_callback' });
  }

  // Сложные callback'и отправляем в AWS
  return await delegateToAWS({ callback_query: callbackQuery }, res);
}

async function delegateToAWS(data, res) {
  try {
    const awsEndpoint = process.env.AWS_N8N_ENDPOINT || 'https://your-aws-n8n.com/webhook/telegram';
    
    console.log('🔄 Delegating to AWS n8n:', awsEndpoint);
    
    const response = await fetch(awsEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Forwarded-From': 'vercel-edge'
      },
      body: JSON.stringify(data)
    });

    if (!response.ok) {
      throw new Error(`AWS n8n responded with status: ${response.status}`);
    }

    const result = await response.json();
    
    await logWorkflowExecution('telegram_aws_delegation', {
      delegated: true,
      aws_response: result
    }, 'completed');

    return res.status(200).json({ 
      ok: true, 
      processed: 'aws_delegation',
      aws_result: result 
    });

  } catch (error) {
    console.error('❌ AWS delegation failed:', error);
    
    // Fallback: отправляем сообщение об ошибке
    if (data.message) {
      await sendTelegramMessage(data.message.chat.id, 
        '⚠️ Временные технические проблемы. Попробуйте позже.'
      );
    }

    await logError('aws_delegation', error.message, data);
    
    return res.status(200).json({ 
      ok: true, 
      processed: 'error_fallback',
      error: error.message 
    });
  }
}

async function sendTelegramMessage(chatId, text, options = {}) {
  const botToken = process.env.TELEGRAM_BOT_TOKEN;
  
  if (!botToken) {
    console.error('❌ TELEGRAM_BOT_TOKEN not configured');
    return false;
  }

  try {
    const response = await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: chatId,
        text: text,
        parse_mode: 'HTML',
        ...options
      })
    });

    const result = await response.json();
    
    if (!result.ok) {
      console.error('❌ Telegram API error:', result);
      return false;
    }

    return true;
  } catch (error) {
    console.error('❌ Send message error:', error);
    return false;
  }
}

async function getSystemStatus() {
  const startTime = Date.now();
  
  const checks = await Promise.allSettled([
    // Проверка AWS n8n
    fetch(process.env.AWS_N8N_ENDPOINT || 'https://your-aws-n8n.com/health', {
      method: 'GET',
      timeout: 5000
    }).then(r => r.ok),
    
    // Проверка Supabase
    fetch(process.env.SUPABASE_URL + '/rest/v1/', {
      headers: { 'apikey': process.env.SUPABASE_ANON_KEY }
    }).then(r => r.ok)
  ]);

  return {
    startTime,
    aws_n8n: checks[0].status === 'fulfilled' && checks[0].value,
    supabase: checks[1].status === 'fulfilled' && checks[1].value,
    edge_function: true
  };
}

async function logWorkflowExecution(workflowName, data, status) {
  try {
    // Логирование в Supabase через Edge Function
    if (process.env.SUPABASE_URL && process.env.SUPABASE_ANON_KEY) {
      await fetch(process.env.SUPABASE_URL + '/rest/v1/workflow_analytics', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': process.env.SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${process.env.SUPABASE_ANON_KEY}`
        },
        body: JSON.stringify({
          workflow_name: workflowName,
          execution_time: new Date().toISOString(),
          duration_ms: Date.now() % 1000, // Примерное время
          status: status,
          input_data: data,
          platform: 'vercel_edge'
        })
      });
    }
  } catch (error) {
    console.error('⚠️ Logging failed:', error);
  }
}

async function logError(source, message, data) {
  try {
    if (process.env.SUPABASE_URL && process.env.SUPABASE_ANON_KEY) {
      await fetch(process.env.SUPABASE_URL + '/rest/v1/error_logs', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': process.env.SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${process.env.SUPABASE_ANON_KEY}`
        },
        body: JSON.stringify({
          source: source,
          error_message: message,
          error_data: data,
          timestamp: new Date().toISOString(),
          platform: 'vercel_edge'
        })
      });
    }
  } catch (error) {
    console.error('⚠️ Error logging failed:', error);
  }
}
