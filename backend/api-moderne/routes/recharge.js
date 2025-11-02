const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { asyncHandler, TransactionError } = require('../middleware/errorHandler');
const logger = require('../utils/logger');
const MavianceService = require('../services/MavianceService');
const MTNService = require('../services/MTNService');
const OrangeService = require('../services/OrangeService');
const USSDService = require('../services/USSDService');

const router = express.Router();

/**
 * POST /api/recharge
 * Recharger du crédit sur un numéro de téléphone
 */
router.post('/', asyncHandler(async (req, res) => {
  const {
    phoneNumber,
    amount,
    payItemId,
    customerInfo,
    operator,
    paymentMethod = 'balance'
  } = req.body;

  // Validation des données
  if (!phoneNumber || !amount || !customerInfo) {
    throw new TransactionError('Missing required fields: phoneNumber, amount, customerInfo');
  }

  if (amount <= 0 || amount > 100000) { // Max 100,000 XAF
    throw new TransactionError('Amount must be between 1 and 100,000 XAF');
  }

  // Validation du numéro de téléphone camerounais
  const phoneRegex = /^(6[5-9]\d{7})$/;
  const cleanPhone = phoneNumber.replace(/[\s\-\+]/g, '').replace(/^237/, '');
  
  if (!phoneRegex.test(cleanPhone)) {
    throw new TransactionError('Invalid Cameroon phone number format');
  }

  // Détection automatique de l'opérateur si non fourni
  let detectedOperator = operator;
  if (!detectedOperator) {
    const prefix = cleanPhone.substring(0, 2);
    if (['67', '68', '55'].includes(prefix)) {
      detectedOperator = 'MTN';
    } else if (['69', '65', '59'].includes(prefix)) {
      detectedOperator = 'Orange';
    } else if (['66'].includes(prefix)) {
      detectedOperator = 'Camtel';
    } else {
      throw new TransactionError('Unable to detect operator from phone number');
    }
  }

  // Générer un ID de transaction unique
  const transactionId = uuidv4();
  
  logger.info('Recharge request initiated', {
    transactionId,
    phoneNumber: cleanPhone,
    operator: detectedOperator,
    amount,
    paymentMethod
  });

  try {
    let result;

    // Choisir le service selon l'opérateur et la méthode
    switch (detectedOperator.toUpperCase()) {
      case 'MTN':
        if (paymentMethod === 'ussd') {
          result = await USSDService.generateMTNRechargeCode(cleanPhone, amount);
        } else {
          result = await MTNService.rechargeCredit({
            phoneNumber: cleanPhone,
            amount,
            transactionId,
            customerInfo
          });
        }
        break;

      case 'ORANGE':
        if (paymentMethod === 'ussd') {
          result = await USSDService.generateOrangeRechargeCode(cleanPhone, amount);
        } else {
          result = await OrangeService.rechargeCredit({
            phoneNumber: cleanPhone,
            amount,
            transactionId,
            customerInfo
          });
        }
        break;

      case 'CAMTEL':
        // Pour l'instant, Camtel via USSD uniquement
        result = await USSDService.generateCamtelRechargeCode(cleanPhone, amount);
        break;

      default:
        // Fallback vers Maviance pour tous les opérateurs
        result = await MavianceService.rechargeCredit({
          phoneNumber: cleanPhone,
          amount,
          payItemId: payItemId || 'auto',
          customerInfo
        });
    }

    // Logger la transaction réussie
    logger.logTransaction({
      id: transactionId,
      type: 'recharge',
      userId: customerInfo.userId || 'anonymous',
      phoneNumber: cleanPhone,
      operator: detectedOperator,
      amount,
      status: result.success ? 'completed' : 'failed',
      paymentMethod
    });

    res.json({
      success: true,
      transactionId,
      operator: detectedOperator,
      phoneNumber: cleanPhone,
      amount,
      result,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    logger.logExternalAPIError(detectedOperator, '/recharge', error, {
      transactionId,
      phoneNumber: cleanPhone,
      amount
    });

    // En cas d'échec de l'API principale, essayer USSD en fallback
    if (paymentMethod !== 'ussd') {
      logger.info('Attempting USSD fallback for failed recharge', { transactionId });
      
      try {
        const ussdResult = await USSDService.generateRechargeCode(detectedOperator, cleanPhone, amount);
        
        res.json({
          success: true,
          transactionId,
          operator: detectedOperator,
          phoneNumber: cleanPhone,
          amount,
          result: ussdResult,
          fallbackUsed: true,
          timestamp: new Date().toISOString()
        });
        return;
      } catch (ussdError) {
        logger.error('USSD fallback also failed', { transactionId, error: ussdError.message });
      }
    }

    throw new TransactionError(
      `Recharge failed: ${error.message}`,
      { transactionId, operator: detectedOperator, originalError: error.message }
    );
  }
}));

/**
 * GET /api/recharge/operators
 * Liste des opérateurs supportés
 */
router.get('/operators', asyncHandler(async (req, res) => {
  res.json({
    success: true,
    operators: [
      {
        name: 'MTN',
        code: 'MTN',
        prefixes: ['67', '68', '55'],
        minAmount: 100,
        maxAmount: 100000,
        methods: ['api', 'ussd'],
        ussdCode: '*126#'
      },
      {
        name: 'Orange',
        code: 'ORANGE',
        prefixes: ['69', '65', '59'],
        minAmount: 100,
        maxAmount: 100000,
        methods: ['api', 'ussd'],
        ussdCode: '*144#'
      },
      {
        name: 'Camtel',
        code: 'CAMTEL',
        prefixes: ['66'],
        minAmount: 100,
        maxAmount: 50000,
        methods: ['ussd'],
        ussdCode: '*370#'
      }
    ],
    timestamp: new Date().toISOString()
  });
}));

/**
 * GET /api/recharge/amounts
 * Montants prédéfinis pour la recharge
 */
router.get('/amounts', asyncHandler(async (req, res) => {
  const { operator } = req.query;
  
  const amounts = {
    MTN: [100, 200, 500, 1000, 2000, 5000, 10000, 20000],
    ORANGE: [100, 200, 500, 1000, 2000, 5000, 10000, 20000],
    CAMTEL: [100, 200, 500, 1000, 2000, 5000, 10000]
  };

  res.json({
    success: true,
    operator: operator?.toUpperCase(),
    amounts: operator ? amounts[operator.toUpperCase()] || amounts.MTN : amounts,
    timestamp: new Date().toISOString()
  });
}));

/**
 * POST /api/recharge/validate
 * Valider une demande de recharge (dry-run)
 */
router.post('/validate', asyncHandler(async (req, res) => {
  const { phoneNumber, amount, operator } = req.body;

  if (!phoneNumber || !amount) {
    throw new TransactionError('Missing required fields for validation');
  }

  // Validation du numéro
  const phoneRegex = /^(6[5-9]\d{7})$/;
  const cleanPhone = phoneNumber.replace(/[\s\-\+]/g, '').replace(/^237/, '');
  
  if (!phoneRegex.test(cleanPhone)) {
    return res.json({
      success: false,
      valid: false,
      errors: ['Invalid phone number format'],
      suggestions: ['Use format: 6XXXXXXXX (without country code)']
    });
  }

  // Validation du montant
  if (amount <= 0 || amount > 100000) {
    return res.json({
      success: false,
      valid: false,
      errors: ['Amount must be between 1 and 100,000 XAF']
    });
  }

  // Détection de l'opérateur
  const prefix = cleanPhone.substring(0, 2);
  let detectedOperator;
  
  if (['67', '68', '55'].includes(prefix)) {
    detectedOperator = 'MTN';
  } else if (['69', '65', '59'].includes(prefix)) {
    detectedOperator = 'Orange';
  } else if (['66'].includes(prefix)) {
    detectedOperator = 'Camtel';
  }

  const validation = {
    success: true,
    valid: true,
    phoneNumber: cleanPhone,
    detectedOperator,
    amount,
    estimatedFee: Math.ceil(amount * 0.02), // 2% de frais
    total: amount + Math.ceil(amount * 0.02),
    availableMethods: detectedOperator === 'Camtel' ? ['ussd'] : ['api', 'ussd'],
    timestamp: new Date().toISOString()
  };

  res.json(validation);
}));

module.exports = router;