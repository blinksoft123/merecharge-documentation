const logger = require('../utils/logger');

/**
 * Gestionnaire d'erreurs global pour Express
 */
const errorHandler = (error, req, res, next) => {
  logger.error('Unhandled error:', {
    error: error.message,
    stack: error.stack,
    path: req.path,
    method: req.method,
    ip: req.ip,
    body: req.body,
    query: req.query,
    params: req.params
  });

  // Erreurs de validation
  if (error.name === 'ValidationError') {
    return res.status(400).json({
      success: false,
      error: 'Validation Error',
      code: 'VALIDATION_ERROR',
      details: error.details || error.message,
      timestamp: new Date().toISOString()
    });
  }

  // Erreurs JWT
  if (error.name === 'JsonWebTokenError') {
    return res.status(401).json({
      success: false,
      error: 'Invalid token',
      code: 'INVALID_TOKEN',
      timestamp: new Date().toISOString()
    });
  }

  if (error.name === 'TokenExpiredError') {
    return res.status(401).json({
      success: false,
      error: 'Token expired',
      code: 'TOKEN_EXPIRED',
      timestamp: new Date().toISOString()
    });
  }

  // Erreurs Firebase
  if (error.code && error.code.startsWith('auth/')) {
    return res.status(401).json({
      success: false,
      error: 'Authentication error',
      code: error.code,
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }

  // Erreurs de rate limiting
  if (error.status === 429) {
    return res.status(429).json({
      success: false,
      error: 'Too many requests',
      code: 'RATE_LIMIT_EXCEEDED',
      message: 'Please try again later',
      retryAfter: error.retryAfter,
      timestamp: new Date().toISOString()
    });
  }

  // Erreurs de requête malformée
  if (error.type === 'entity.parse.failed') {
    return res.status(400).json({
      success: false,
      error: 'Invalid JSON in request body',
      code: 'MALFORMED_JSON',
      timestamp: new Date().toISOString()
    });
  }

  // Erreurs de taille de payload
  if (error.type === 'entity.too.large') {
    return res.status(413).json({
      success: false,
      error: 'Request payload too large',
      code: 'PAYLOAD_TOO_LARGE',
      limit: error.limit,
      timestamp: new Date().toISOString()
    });
  }

  // Erreurs réseau/timeout
  if (error.code === 'ECONNREFUSED' || error.code === 'ETIMEDOUT') {
    return res.status(503).json({
      success: false,
      error: 'Service temporarily unavailable',
      code: 'SERVICE_UNAVAILABLE',
      message: 'External service is currently unavailable. Please try again later.',
      timestamp: new Date().toISOString()
    });
  }

  // Erreur par défaut (500 Internal Server Error)
  const status = error.status || error.statusCode || 500;
  const isProduction = process.env.NODE_ENV === 'production';

  res.status(status).json({
    success: false,
    error: isProduction ? 'Internal server error' : error.message,
    code: error.code || 'INTERNAL_ERROR',
    ...(isProduction ? {} : {
      stack: error.stack,
      details: error.details
    }),
    timestamp: new Date().toISOString()
  });
};

/**
 * Middleware pour les routes non trouvées (404)
 */
const notFoundHandler = (req, res) => {
  res.status(404).json({
    success: false,
    error: 'Route not found',
    code: 'ROUTE_NOT_FOUND',
    path: req.originalUrl,
    method: req.method,
    timestamp: new Date().toISOString()
  });
};

/**
 * Wrapper pour les fonctions async dans les routes
 * Évite de devoir mettre try/catch partout
 */
const asyncHandler = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

/**
 * Créer une erreur personnalisée
 */
class CustomError extends Error {
  constructor(message, statusCode = 500, code = 'CUSTOM_ERROR', details = null) {
    super(message);
    this.name = this.constructor.name;
    this.status = statusCode;
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    this.timestamp = new Date().toISOString();

    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Erreurs spécifiques au métier
 */
class TransactionError extends CustomError {
  constructor(message, details = null) {
    super(message, 400, 'TRANSACTION_ERROR', details);
  }
}

class PaymentError extends CustomError {
  constructor(message, details = null) {
    super(message, 402, 'PAYMENT_ERROR', details);
  }
}

class ExternalAPIError extends CustomError {
  constructor(service, message, details = null) {
    super(`${service}: ${message}`, 502, 'EXTERNAL_API_ERROR', details);
    this.service = service;
  }
}

module.exports = {
  errorHandler,
  notFoundHandler,
  asyncHandler,
  CustomError,
  TransactionError,
  PaymentError,
  ExternalAPIError
};