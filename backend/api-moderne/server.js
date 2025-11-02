const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const bodyParser = require('body-parser');
require('dotenv').config();

// Import des modules locaux
const logger = require('./utils/logger');
const { authenticateAPI } = require('./middleware/auth');
const { errorHandler } = require('./middleware/errorHandler');

// Import des routes
const pingRoutes = require('./routes/ping');
const transactionRoutes = require('./routes/transactions');
const rechargeRoutes = require('./routes/recharge');
const voucherRoutes = require('./routes/voucher');
const depositRoutes = require('./routes/deposit');
const withdrawRoutes = require('./routes/withdraw');
const servicesRoutes = require('./routes/services');
const ussdRoutes = require('./routes/ussd');
const webhookRoutes = require('./routes/webhooks');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware de sécurité
app.use(helmet());
app.use(compression());

// CORS Configuration
const corsOptions = {
  origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : ['http://localhost:3000'],
  credentials: true,
  optionsSuccessStatus: 200,
};
app.use(cors(corsOptions));

// Rate Limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // limit each IP to 100 requests per windowMs
  message: {
    error: 'Too many requests from this IP, please try again later.',
    retryAfter: Math.ceil((parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 900000) / 1000)
  },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api', limiter);

// Body parsing
app.use(bodyParser.json({ limit: '10mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '10mb' }));

// Logging middleware
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    timestamp: new Date().toISOString()
  });
  next();
});

// Health check (sans authentification)
app.get('/', (req, res) => {
  res.json({
    service: 'Merecharge Backend API',
    version: '1.0.0',
    status: 'running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Routes API avec authentification
app.use('/api/ping', pingRoutes);
app.use('/api/transactions', authenticateAPI, transactionRoutes);
app.use('/api/recharge', authenticateAPI, rechargeRoutes);
app.use('/api/voucher', authenticateAPI, voucherRoutes);
app.use('/api/deposit', authenticateAPI, depositRoutes);
app.use('/api/withdraw', authenticateAPI, withdrawRoutes);
app.use('/api/services', authenticateAPI, servicesRoutes);
app.use('/api/ussd', authenticateAPI, ussdRoutes);

// Routes webhooks (sans auth API mais avec validation spéciale)
app.use('/api/webhooks', webhookRoutes);

// Route 404
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found',
    path: req.originalUrl,
    method: req.method
  });
});

// Gestionnaire d'erreurs global
app.use(errorHandler);

// Démarrage du serveur
const server = app.listen(PORT, () => {
  logger.info(`🚀 Merecharge Backend Server started on port ${PORT}`, {
    environment: process.env.NODE_ENV,
    timestamp: new Date().toISOString()
  });
  
  // Log des informations importantes au démarrage
  logger.info('Server Configuration:', {
    nodeEnv: process.env.NODE_ENV,
    port: PORT,
    corsOrigins: corsOptions.origin,
    rateLimiting: `${limiter.max} requests per ${Math.ceil(limiter.windowMs / 60000)} minutes`
  });
});

// Gestion graceful du shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  server.close(() => {
    logger.info('Process terminated');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  server.close(() => {
    logger.info('Process terminated');
    process.exit(0);
  });
});

// Gestion des erreurs non catchées
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', { promise, reason });
});

process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', { error: error.message, stack: error.stack });
  process.exit(1);
});

module.exports = app;