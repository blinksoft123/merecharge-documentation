const express = require('express');
const { asyncHandler } = require('../middleware/errorHandler');
const logger = require('../utils/logger');

const router = express.Router();

/**
 * GET /api/ping
 * Test de connectivité basique
 */
router.get('/', asyncHandler(async (req, res) => {
  const responseData = {
    success: true,
    message: 'Merecharge Backend API is running',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    uptime: Math.floor(process.uptime()),
    memory: {
      used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024) + ' MB',
      total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024) + ' MB'
    }
  };

  logger.info('Ping request successful', {
    ip: req.ip,
    userAgent: req.get('User-Agent')
  });

  res.json(responseData);
}));

/**
 * GET /api/ping/health
 * Health check détaillé
 */
router.get('/health', asyncHandler(async (req, res) => {
  const health = {
    success: true,
    status: 'healthy',
    timestamp: new Date().toISOString(),
    checks: {
      server: 'OK',
      memory: 'OK',
      uptime: 'OK'
    },
    details: {
      uptime: `${Math.floor(process.uptime())} seconds`,
      memory: {
        used: process.memoryUsage().heapUsed,
        total: process.memoryUsage().heapTotal,
        external: process.memoryUsage().external,
        rss: process.memoryUsage().rss
      },
      environment: process.env.NODE_ENV || 'development',
      node: process.version,
      platform: process.platform,
      arch: process.arch
    }
  };

  // Vérifier la mémoire (alerte si > 500MB)
  const memoryUsedMB = process.memoryUsage().heapUsed / 1024 / 1024;
  if (memoryUsedMB > 500) {
    health.checks.memory = 'WARNING';
    health.details.memory.warning = 'High memory usage detected';
  }

  // Vérifier l'uptime (alerte si < 60 secondes = récent redémarrage)
  if (process.uptime() < 60) {
    health.checks.uptime = 'INFO';
    health.details.uptime_status = 'Recently started';
  }

  res.json(health);
}));

/**
 * POST /api/ping/echo
 * Echo du payload pour tester les POST
 */
router.post('/echo', asyncHandler(async (req, res) => {
  res.json({
    success: true,
    message: 'Echo successful',
    timestamp: new Date().toISOString(),
    received: {
      method: req.method,
      headers: {
        'content-type': req.get('Content-Type'),
        'content-length': req.get('Content-Length'),
        'x-api-key': req.get('x-api-key') ? '[PRÉSENT]' : '[ABSENT]'
      },
      body: req.body,
      query: req.query
    }
  });
}));

module.exports = router;