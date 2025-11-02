const winston = require('winston');
const path = require('path');

// Configuration des formats de log
const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.json(),
  winston.format.prettyPrint()
);

const consoleFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({ format: 'HH:mm:ss' }),
  winston.format.printf(({ level, message, timestamp, ...meta }) => {
    let metaStr = '';
    if (Object.keys(meta).length > 0) {
      metaStr = JSON.stringify(meta, null, 2);
    }
    return `${timestamp} [${level}]: ${message} ${metaStr}`;
  })
);

// Configuration du logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: logFormat,
  defaultMeta: { service: 'merecharge-backend' },
  transports: [
    // Logs d'erreurs dans un fichier séparé
    new winston.transports.File({
      filename: path.join(__dirname, '../logs/error.log'),
      level: 'error',
      maxsize: 5242880, // 5MB
      maxFiles: 5,
    }),
    
    // Tous les logs dans un fichier général
    new winston.transports.File({
      filename: path.join(__dirname, '../logs/combined.log'),
      maxsize: 5242880, // 5MB
      maxFiles: 5,
    }),
  ],
});

// En développement, log aussi dans la console
if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: consoleFormat
  }));
}

// Méthodes utilitaires pour le logging
logger.logRequest = (req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    const logData = {
      method: req.method,
      url: req.originalUrl,
      status: res.statusCode,
      duration: `${duration}ms`,
      ip: req.ip,
      userAgent: req.get('User-Agent')
    };
    
    if (res.statusCode >= 400) {
      logger.error('Request failed', logData);
    } else {
      logger.info('Request completed', logData);
    }
  });
  
  next();
};

// Log des transactions pour audit
logger.logTransaction = (transactionData) => {
  logger.info('Transaction processed', {
    type: 'TRANSACTION',
    transactionId: transactionData.id,
    userId: transactionData.userId,
    amount: transactionData.amount,
    status: transactionData.status,
    operator: transactionData.operator,
    timestamp: new Date().toISOString()
  });
};

// Log des erreurs API externes
logger.logExternalAPIError = (service, endpoint, error, requestData = null) => {
  logger.error(`External API Error - ${service}`, {
    service,
    endpoint,
    error: error.message,
    stack: error.stack,
    requestData: requestData ? JSON.stringify(requestData) : null,
    timestamp: new Date().toISOString()
  });
};

// Log des erreurs de sécurité
logger.logSecurityEvent = (event, details = {}) => {
  logger.warn('Security Event', {
    type: 'SECURITY',
    event,
    details,
    timestamp: new Date().toISOString()
  });
};

module.exports = logger;