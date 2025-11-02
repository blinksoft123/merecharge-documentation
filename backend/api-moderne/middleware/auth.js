const jwt = require('jsonwebtoken');
const admin = require('firebase-admin');
const logger = require('../utils/logger');

// Initialisation Firebase Admin (si pas déjà fait)
if (!admin.apps.length && process.env.NODE_ENV === 'production') {
  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        privateKeyId: process.env.FIREBASE_PRIVATE_KEY_ID,
        privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        clientId: process.env.FIREBASE_CLIENT_ID,
        authUri: process.env.FIREBASE_AUTH_URI,
        tokenUri: process.env.FIREBASE_TOKEN_URI,
      }),
      projectId: process.env.FIREBASE_PROJECT_ID,
    });
    logger.info('Firebase Admin initialized successfully');
  } catch (error) {
    logger.error('Failed to initialize Firebase Admin:', error);
  }
} else if (process.env.NODE_ENV === 'development') {
  logger.info('Firebase Admin skipped for development mode');
}

/**
 * Middleware d'authentification API Key
 * Vérifie la présence et validité de la clé API
 */
const authenticateAPI = (req, res, next) => {
  const apiKey = req.headers['x-api-key'];
  const expectedApiKey = process.env.API_KEY;

  if (!apiKey) {
    logger.logSecurityEvent('Missing API Key', {
      ip: req.ip,
      path: req.path,
      method: req.method
    });
    
    return res.status(401).json({
      success: false,
      error: 'API key is required',
      code: 'MISSING_API_KEY'
    });
  }

  if (apiKey !== expectedApiKey) {
    logger.logSecurityEvent('Invalid API Key', {
      ip: req.ip,
      path: req.path,
      method: req.method,
      providedKey: apiKey.substring(0, 8) + '...' // Log seulement les premiers caractères
    });
    
    return res.status(403).json({
      success: false,
      error: 'Invalid API key',
      code: 'INVALID_API_KEY'
    });
  }

  next();
};

/**
 * Middleware d'authentification Firebase Token
 * Vérifie le token Firebase ID pour les requêtes utilisateur
 */
const authenticateFirebaseToken = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      error: 'Authorization token is required',
      code: 'MISSING_TOKEN'
    });
  }

  const token = authHeader.split(' ')[1];

  try {
    // Vérifier le token Firebase
    const decodedToken = await admin.auth().verifyIdToken(token);
    
    // Ajouter les infos utilisateur à la requête
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      emailVerified: decodedToken.email_verified,
      name: decodedToken.name,
      picture: decodedToken.picture,
    };

    logger.info('User authenticated', {
      userId: req.user.uid,
      email: req.user.email,
      path: req.path,
      method: req.method
    });

    next();
  } catch (error) {
    logger.logSecurityEvent('Invalid Firebase Token', {
      error: error.message,
      ip: req.ip,
      path: req.path,
      method: req.method
    });

    return res.status(403).json({
      success: false,
      error: 'Invalid or expired token',
      code: 'INVALID_TOKEN',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Middleware combiné : API Key + Firebase Token
 * Pour les routes nécessitant les deux
 */
const authenticateAPIAndUser = (req, res, next) => {
  authenticateAPI(req, res, (err) => {
    if (err) return next(err);
    authenticateFirebaseToken(req, res, next);
  });
};

/**
 * Middleware d'autorisation admin
 * Vérifie si l'utilisateur a les droits admin
 */
const requireAdmin = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required',
        code: 'AUTH_REQUIRED'
      });
    }

    // Vérifier les custom claims pour le rôle admin
    const userRecord = await admin.auth().getUser(req.user.uid);
    const customClaims = userRecord.customClaims || {};

    if (!customClaims.admin && !customClaims.role === 'admin') {
      logger.logSecurityEvent('Unauthorized admin access attempt', {
        userId: req.user.uid,
        email: req.user.email,
        path: req.path,
        method: req.method
      });

      return res.status(403).json({
        success: false,
        error: 'Admin privileges required',
        code: 'INSUFFICIENT_PRIVILEGES'
      });
    }

    next();
  } catch (error) {
    logger.error('Error checking admin privileges:', error);
    return res.status(500).json({
      success: false,
      error: 'Error verifying admin privileges',
      code: 'AUTH_CHECK_ERROR'
    });
  }
};

/**
 * Middleware de validation des webhooks
 * Vérifie la signature des webhooks entrants
 */
const validateWebhookSignature = (req, res, next) => {
  const signature = req.headers['x-webhook-signature'];
  const payload = JSON.stringify(req.body);
  
  if (!signature) {
    logger.logSecurityEvent('Missing webhook signature', {
      ip: req.ip,
      path: req.path,
      headers: req.headers
    });
    
    return res.status(401).json({
      success: false,
      error: 'Webhook signature required',
      code: 'MISSING_SIGNATURE'
    });
  }

  // Ici vous pouvez implémenter la vérification de signature spécifique
  // selon le service (MTN, Orange, etc.)
  
  next();
};

/**
 * Middleware simplifié pour les tests
 * Peut utiliser API key seule en développement
 */
const requireAuth = (req, res, next) => {
  // En mode développement, utiliser juste la clé API
  if (process.env.NODE_ENV === 'development') {
    return authenticateAPI(req, res, next);
  }
  
  // En production, exiger les deux
  return authenticateAPIAndUser(req, res, next);
};

module.exports = {
  authenticateAPI,
  authenticateFirebaseToken,
  authenticateAPIAndUser,
  requireAdmin,
  validateWebhookSignature,
  requireAuth
};
