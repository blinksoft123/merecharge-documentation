const logger = require('../utils/logger');

/**
 * Service USSD pour générer et traiter les codes USSD
 * COMPOSANT CRITIQUE pour le marché camerounais
 */
class USSDService {
  
  /**
   * Générer un code USSD pour recharge MTN
   * Format: *126*MONTANT*NUMERO#
   */
  static async generateMTNRechargeCode(phoneNumber, amount) {
    try {
      const ussdCode = `*126*${amount}*${phoneNumber}#`;
      
      logger.info('MTN USSD code generated', {
        phoneNumber,
        amount,
        ussdCode: ussdCode.replace(/\d{8}/, 'XXXXXXXX') // Masquer le numéro dans les logs
      });

      return {
        success: true,
        method: 'ussd',
        operator: 'MTN',
        ussdCode,
        instructions: [
          `Composez ${ussdCode} sur votre téléphone`,
          'Appuyez sur la touche d\'appel',
          'Suivez les instructions à l\'écran',
          'Confirmez le paiement avec votre PIN MTN Money'
        ],
        estimatedTime: '30-60 secondes',
        phoneNumber,
        amount
      };
    } catch (error) {
      logger.error('Failed to generate MTN USSD code', { error: error.message, phoneNumber, amount });
      throw error;
    }
  }

  /**
   * Générer un code USSD pour recharge Orange
   * Format: *144*MONTANT*NUMERO#
   */
  static async generateOrangeRechargeCode(phoneNumber, amount) {
    try {
      const ussdCode = `*144*${amount}*${phoneNumber}#`;
      
      logger.info('Orange USSD code generated', {
        phoneNumber,
        amount,
        ussdCode: ussdCode.replace(/\d{8}/, 'XXXXXXXX')
      });

      return {
        success: true,
        method: 'ussd',
        operator: 'Orange',
        ussdCode,
        instructions: [
          `Composez ${ussdCode} sur votre téléphone`,
          'Appuyez sur la touche d\'appel',
          'Suivez les instructions à l\'écran',
          'Confirmez le paiement avec votre PIN Orange Money'
        ],
        estimatedTime: '30-60 secondes',
        phoneNumber,
        amount
      };
    } catch (error) {
      logger.error('Failed to generate Orange USSD code', { error: error.message, phoneNumber, amount });
      throw error;
    }
  }

  /**
   * Générer un code USSD pour recharge Camtel
   * Format: *370*MONTANT*NUMERO#
   */
  static async generateCamtelRechargeCode(phoneNumber, amount) {
    try {
      const ussdCode = `*370*${amount}*${phoneNumber}#`;
      
      logger.info('Camtel USSD code generated', {
        phoneNumber,
        amount,
        ussdCode: ussdCode.replace(/\d{8}/, 'XXXXXXXX')
      });

      return {
        success: true,
        method: 'ussd',
        operator: 'Camtel',
        ussdCode,
        instructions: [
          `Composez ${ussdCode} sur votre téléphone`,
          'Appuyez sur la touche d\'appel',
          'Suivez les instructions à l\'écran',
          'Confirmez le paiement'
        ],
        estimatedTime: '30-60 secondes',
        phoneNumber,
        amount
      };
    } catch (error) {
      logger.error('Failed to generate Camtel USSD code', { error: error.message, phoneNumber, amount });
      throw error;
    }
  }

  /**
   * Générer un code USSD générique selon l'opérateur
   */
  static async generateRechargeCode(operator, phoneNumber, amount) {
    switch (operator.toUpperCase()) {
      case 'MTN':
        return await this.generateMTNRechargeCode(phoneNumber, amount);
      case 'ORANGE':
        return await this.generateOrangeRechargeCode(phoneNumber, amount);
      case 'CAMTEL':
        return await this.generateCamtelRechargeCode(phoneNumber, amount);
      default:
        throw new Error(`Unsupported operator for USSD: ${operator}`);
    }
  }

  /**
   * Générer un code USSD pour achat de forfait MTN
   */
  static async generateMTNBundleCode(phoneNumber, bundleCode) {
    try {
      const ussdCode = `*131*${bundleCode}*${phoneNumber}#`;
      
      return {
        success: true,
        method: 'ussd',
        operator: 'MTN',
        type: 'bundle',
        ussdCode,
        instructions: [
          `Composez ${ussdCode} sur votre téléphone`,
          'Appuyez sur la touche d\'appel',
          'Confirmez l\'achat du forfait',
          'Saisissez votre PIN MTN Money'
        ],
        estimatedTime: '30-60 secondes',
        phoneNumber,
        bundleCode
      };
    } catch (error) {
      logger.error('Failed to generate MTN bundle USSD code', { error: error.message, phoneNumber, bundleCode });
      throw error;
    }
  }

  /**
   * Générer un code USSD pour achat de forfait Orange
   */
  static async generateOrangeBundleCode(phoneNumber, bundleCode) {
    try {
      const ussdCode = `*555*${bundleCode}*${phoneNumber}#`;
      
      return {
        success: true,
        method: 'ussd',
        operator: 'Orange',
        type: 'bundle',
        ussdCode,
        instructions: [
          `Composez ${ussdCode} sur votre téléphone`,
          'Appuyez sur la touche d\'appel',
          'Confirmez l\'achat du forfait',
          'Saisissez votre PIN Orange Money'
        ],
        estimatedTime: '30-60 secondes',
        phoneNumber,
        bundleCode
      };
    } catch (error) {
      logger.error('Failed to generate Orange bundle USSD code', { error: error.message, phoneNumber, bundleCode });
      throw error;
    }
  }

  /**
   * Générer un code USSD pour vérification de solde
   */
  static generateBalanceCheckCode(operator) {
    const codes = {
      MTN: '*141#',
      ORANGE: '*144*5#',
      CAMTEL: '*370#'
    };

    const ussdCode = codes[operator.toUpperCase()];
    if (!ussdCode) {
      throw new Error(`Unsupported operator for balance check: ${operator}`);
    }

    return {
      success: true,
      operator: operator.toUpperCase(),
      type: 'balance_check',
      ussdCode,
      instructions: [
        `Composez ${ussdCode} sur votre téléphone`,
        'Appuyez sur la touche d\'appel',
        'Consultez votre solde affiché'
      ]
    };
  }

  /**
   * Générer des codes USSD pour transfert d'argent
   */
  static generateMoneyTransferCode(operator, recipientPhone, amount) {
    let ussdCode;
    let instructions;

    switch (operator.toUpperCase()) {
      case 'MTN':
        ussdCode = `*126*2*${recipientPhone}*${amount}#`;
        instructions = [
          `Composez ${ussdCode}`,
          'Appuyez sur la touche d\'appel',
          'Confirmez le destinataire et le montant',
          'Saisissez votre PIN MTN Money'
        ];
        break;

      case 'ORANGE':
        ussdCode = `*144*2*${recipientPhone}*${amount}#`;
        instructions = [
          `Composez ${ussdCode}`,
          'Appuyez sur la touche d\'appel',
          'Confirmez le destinataire et le montant',
          'Saisissez votre PIN Orange Money'
        ];
        break;

      default:
        throw new Error(`Money transfer not supported for operator: ${operator}`);
    }

    return {
      success: true,
      operator: operator.toUpperCase(),
      type: 'money_transfer',
      ussdCode,
      instructions,
      recipientPhone,
      amount,
      estimatedTime: '1-2 minutes'
    };
  }

  /**
   * Parser les réponses USSD (simulé)
   * En production, ceci nécessiterait une intégration avec les APIs des opérateurs
   */
  static parseUSSDResponse(ussdResponse, operator) {
    // Simulation d'un parser de réponse USSD
    // En réalité, il faudrait intégrer avec les APIs des opérateurs pour obtenir le statut
    
    const successPatterns = {
      MTN: /transaction.*(successful|réussie)/i,
      ORANGE: /opération.*(successful|réussie)/i,
      CAMTEL: /transfer.*(successful|réussi)/i
    };

    const pattern = successPatterns[operator.toUpperCase()];
    const isSuccess = pattern ? pattern.test(ussdResponse) : false;

    return {
      success: isSuccess,
      operator: operator.toUpperCase(),
      originalResponse: ussdResponse,
      parsedStatus: isSuccess ? 'completed' : 'failed',
      timestamp: new Date().toISOString()
    };
  }

  /**
   * Obtenir les codes USSD disponibles pour un opérateur
   */
  static getAvailableCodes(operator) {
    const codes = {
      MTN: {
        recharge: '*126*AMOUNT*PHONE#',
        balance: '*141#',
        bundle: '*131*CODE*PHONE#',
        transfer: '*126*2*PHONE*AMOUNT#',
        menu: '*126#'
      },
      ORANGE: {
        recharge: '*144*AMOUNT*PHONE#',
        balance: '*144*5#',
        bundle: '*555*CODE*PHONE#',
        transfer: '*144*2*PHONE*AMOUNT#',
        menu: '*144#'
      },
      CAMTEL: {
        recharge: '*370*AMOUNT*PHONE#',
        balance: '*370#',
        menu: '*370#'
      }
    };

    return {
      success: true,
      operator: operator.toUpperCase(),
      codes: codes[operator.toUpperCase()] || {},
      timestamp: new Date().toISOString()
    };
  }
}

module.exports = USSDService;