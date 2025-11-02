const axios = require('axios');
const crypto = require('crypto-js');
require('dotenv').config();

class MavianceService {
  constructor() {
    this.baseURL = process.env.S3P_URL;
    this.token = process.env.S3P_KEY;
    this.secret = process.env.S3P_SECRET;
  }

  // Génère la signature d'authentification HMAC-SHA1
  generateAuthHeader(method, url, params = {}) {
    const timestamp = Date.now();
    const nonce = Date.now();
    
    const s3pParams = {
      s3pAuth_nonce: nonce,
      s3pAuth_timestamp: timestamp,
      s3pAuth_signature_method: 'HMAC-SHA1',
      s3pAuth_token: this.token
    };

    const allParams = { ...params, ...s3pParams };
    
    // Nettoie les paramètres (trim les strings)
    Object.keys(allParams).forEach(key => {
      if (typeof allParams[key] === 'string') {
        allParams[key] = allParams[key].trim();
      }
    });

    // Trie les paramètres par ordre alphabétique
    const sortedParams = Object.keys(allParams)
      .sort()
      .reduce((result, key) => {
        result[key] = allParams[key];
        return result;
      }, {});

    // Crée la chaîne de paramètres
    const parameterString = Object.keys(sortedParams)
      .map(key => `${key}=${sortedParams[key]}`)
      .join('&');

    // Crée la base string pour la signature
    const baseString = `${method}&${encodeURIComponent(url)}&${encodeURIComponent(parameterString)}`;
    
    // Génère la signature HMAC-SHA1
    const signature = crypto.HmacSHA1(baseString, this.secret);
    const encodedSignature = crypto.enc.Base64.stringify(signature);

    // Construit l'en-tête d'autorisation
    const authHeader = `s3pAuth s3pAuth_timestamp="${timestamp}", s3pAuth_signature="${encodedSignature}", s3pAuth_nonce="${nonce}", s3pAuth_signature_method="HMAC-SHA1", s3pAuth_token="${this.token}"`;

    return authHeader;
  }

  // Test de ping pour vérifier la connexion
  async ping() {
    try {
      const url = `${this.baseURL}/ping`;
      const authHeader = this.generateAuthHeader('GET', url);
      
      const response = await axios.get(url, {
        headers: {
          'Authorization': authHeader
        }
      });

      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      console.error('Ping failed:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data || error.message
      };
    }
  }

  // Récupère les services disponibles
  async getServices() {
    try {
      const url = `${this.baseURL}/service`;
      const authHeader = this.generateAuthHeader('GET', url);
      
      const response = await axios.get(url, {
        headers: {
          'Authorization': authHeader,
          'x-api-version': '3.0.0'
        }
      });

      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      console.error('Get services failed:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data || error.message
      };
    }
  }

  // Récupère les produits TOPUP (recharge de crédit)
  async getTopupProducts(serviceId) {
    try {
      const url = `${this.baseURL}/topup`;
      const params = { serviceid: serviceId };
      const authHeader = this.generateAuthHeader('GET', url, params);
      
      const response = await axios.get(url, {
        headers: {
          'Authorization': authHeader
        },
        params: params
      });

      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      console.error('Get topup products failed:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data || error.message
      };
    }
  }

  // Récupère les produits VOUCHER (forfaits)
  async getVoucherProducts(serviceId) {
    try {
      const url = `${this.baseURL}/voucher`;
      const params = { serviceid: serviceId };
      const authHeader = this.generateAuthHeader('GET', url, params);
      
      const response = await axios.get(url, {
        headers: {
          'Authorization': authHeader
        },
        params: params
      });

      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      console.error('Get voucher products failed:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data || error.message
      };
    }
  }

  // Crée un devis (quote)
  async createQuote(payItemId, amount) {
    try {
      const url = `${this.baseURL}/quotestd`;
      const body = {
        payItemId: payItemId,
        amount: amount
      };
      
      const authHeader = this.generateAuthHeader('POST', url, body);
      
      const response = await axios.post(url, body, {
        headers: {
          'Authorization': authHeader,
          'Content-Type': 'application/json'
        }
      });

      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      console.error('Create quote failed:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data || error.message
      };
    }
  }

  // Exécute la collecte (paiement)
  async collectPayment(quoteId, customerData, transactionId) {
    try {
      const url = `${this.baseURL}/collectstd`;
      const body = {
        quoteId: quoteId,
        customerPhonenumber: customerData.phone,
        customerEmailaddress: customerData.email,
        customerName: customerData.name,
        customerAddress: customerData.address,
        serviceNumber: customerData.serviceNumber,
        trid: transactionId
      };
      
      const authHeader = this.generateAuthHeader('POST', url, body);
      
      const response = await axios.post(url, body, {
        headers: {
          'Authorization': authHeader,
          'Content-Type': 'application/json'
        }
      });

      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      console.error('Collect payment failed:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data || error.message
      };
    }
  }

  // Vérifie le statut d'une transaction
  async verifyTransaction(transactionId) {
    try {
      const url = `${this.baseURL}/verifytx`;
      const params = { trid: transactionId };
      const authHeader = this.generateAuthHeader('GET', url, params);
      
      const response = await axios.get(url, {
        headers: {
          'Authorization': authHeader
        },
        params: params
      });

      return {
        success: true,
        data: response.data
      };
    } catch (error) {
      console.error('Verify transaction failed:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data || error.message
      };
    }
  }

  // Recharge de crédit (TOPUP)
  async rechargeCredit(phoneNumber, amount, payItemId, customerInfo) {
    try {
      // Étape 1: Créer un devis
      const quoteResult = await this.createQuote(payItemId, amount);
      if (!quoteResult.success) {
        return quoteResult;
      }

      const quoteId = quoteResult.data.quoteId;
      const transactionId = `TR${Date.now()}`;

      // Étape 2: Exécuter le paiement
      const customerData = {
        phone: customerInfo.phone,
        email: customerInfo.email,
        name: customerInfo.name,
        address: customerInfo.address,
        serviceNumber: phoneNumber
      };

      const collectResult = await this.collectPayment(quoteId, customerData, transactionId);
      if (!collectResult.success) {
        return collectResult;
      }

      // Étape 3: Vérifier la transaction (optionnel)
      const verifyResult = await this.verifyTransaction(transactionId);

      return {
        success: true,
        data: {
          transactionId: transactionId,
          quoteId: quoteId,
          collectResult: collectResult.data,
          verifyResult: verifyResult.success ? verifyResult.data : null
        }
      };
    } catch (error) {
      console.error('Recharge credit failed:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  // Achat de forfait (VOUCHER)
  async purchaseVoucher(phoneNumber, payItemId, customerInfo) {
    try {
      // Pour les forfaits, le montant est souvent inclus dans le payItemId
      // On peut utiliser un montant par défaut ou le récupérer des détails du produit
      const amount = 1000; // Montant par défaut, à ajuster selon le forfait

      // Étape 1: Créer un devis
      const quoteResult = await this.createQuote(payItemId, amount);
      if (!quoteResult.success) {
        return quoteResult;
      }

      const quoteId = quoteResult.data.quoteId;
      const transactionId = `VR${Date.now()}`;

      // Étape 2: Exécuter le paiement
      const customerData = {
        phone: customerInfo.phone,
        email: customerInfo.email,
        name: customerInfo.name,
        address: customerInfo.address,
        serviceNumber: phoneNumber
      };

      const collectResult = await this.collectPayment(quoteId, customerData, transactionId);
      if (!collectResult.success) {
        return collectResult;
      }

      // Étape 3: Vérifier la transaction
      const verifyResult = await this.verifyTransaction(transactionId);

      return {
        success: true,
        data: {
          transactionId: transactionId,
          quoteId: quoteId,
          collectResult: collectResult.data,
          verifyResult: verifyResult.success ? verifyResult.data : null
        }
      };
    } catch (error) {
      console.error('Purchase voucher failed:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  // Dépôt d'argent (CASHIN)
  async depositMoney(amount, payItemId, customerInfo) {
    try {
      const quoteResult = await this.createQuote(payItemId, amount);
      if (!quoteResult.success) {
        return quoteResult;
      }

      const quoteId = quoteResult.data.quoteId;
      const transactionId = `DP${Date.now()}`;

      const customerData = {
        phone: customerInfo.phone,
        email: customerInfo.email,
        name: customerInfo.name,
        address: customerInfo.address,
        serviceNumber: customerInfo.phone // Pour les dépôts, on utilise le même numéro
      };

      const collectResult = await this.collectPayment(quoteId, customerData, transactionId);
      if (!collectResult.success) {
        return collectResult;
      }

      const verifyResult = await this.verifyTransaction(transactionId);

      return {
        success: true,
        data: {
          transactionId: transactionId,
          quoteId: quoteId,
          collectResult: collectResult.data,
          verifyResult: verifyResult.success ? verifyResult.data : null
        }
      };
    } catch (error) {
      console.error('Deposit money failed:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  // Retrait d'argent (CASHOUT)
  async withdrawMoney(amount, payItemId, customerInfo) {
    try {
      const quoteResult = await this.createQuote(payItemId, amount);
      if (!quoteResult.success) {
        return quoteResult;
      }

      const quoteId = quoteResult.data.quoteId;
      const transactionId = `WD${Date.now()}`;

      const customerData = {
        phone: customerInfo.phone,
        email: customerInfo.email,
        name: customerInfo.name,
        address: customerInfo.address,
        serviceNumber: customerInfo.payerNumber // Numéro vers lequel retirer
      };

      const collectResult = await this.collectPayment(quoteId, customerData, transactionId);
      if (!collectResult.success) {
        return collectResult;
      }

      const verifyResult = await this.verifyTransaction(transactionId);

      return {
        success: true,
        data: {
          transactionId: transactionId,
          quoteId: quoteId,
          collectResult: collectResult.data,
          verifyResult: verifyResult.success ? verifyResult.data : null
        }
      };
    } catch (error) {
      console.error('Withdraw money failed:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }
}

module.exports = MavianceService;