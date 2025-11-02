const express = require('express');
const MavianceService = require('./maviance_service');
const callboxRoutes = require('./routes/callbox');
const CallBoxSyncService = require('./services/callbox-sync');
const app = express();
const port = 3000;

app.use(express.json());

const API_KEY = 'votre_cle_api_secrete'; // À remplacer par une vraie clé
const mavianceService = new MavianceService();
const callboxSyncService = new CallBoxSyncService(`http://localhost:${port}`);

const apiKeyAuth = (req, res, next) => {
  const providedApiKey = req.headers['x-api-key'];
  if (!providedApiKey || providedApiKey !== API_KEY) {
    return res.status(401).send({ error: 'Accès non autorisé.' });
  }
  next();
};

app.get('/', (req, res) => {
  res.send('Serveur MeRecharge est en ligne !');
});

// Test de ping avec Maviance
app.get('/api/ping', apiKeyAuth, async (req, res) => {
  try {
    const result = await mavianceService.ping();
    res.status(200).send(result);
  } catch (error) {
    res.status(500).send({ error: 'Erreur lors du ping', details: error.message });
  }
});

// Récupérer les services disponibles
app.get('/api/services', apiKeyAuth, async (req, res) => {
  try {
    const result = await mavianceService.getServices();
    res.status(200).send(result);
  } catch (error) {
    res.status(500).send({ error: 'Erreur lors de la récupération des services', details: error.message });
  }
});

// Recharge de crédit
app.post('/api/recharge', apiKeyAuth, async (req, res) => {
  try {
    const { phoneNumber, amount, payItemId, customerInfo } = req.body;
    
    if (!phoneNumber || !amount || !payItemId || !customerInfo) {
      return res.status(400).send({ error: 'Paramètres manquants: phoneNumber, amount, payItemId, customerInfo sont requis.' });
    }

    const result = await mavianceService.rechargeCredit(phoneNumber, amount, payItemId, customerInfo);
    
    if (result.success) {
      res.status(200).send(result);
    } else {
      res.status(400).send(result);
    }
  } catch (error) {
    res.status(500).send({ error: 'Erreur lors de la recharge', details: error.message });
  }
});

// Achat de forfait
app.post('/api/voucher', apiKeyAuth, async (req, res) => {
  try {
    const { phoneNumber, payItemId, customerInfo } = req.body;
    
    if (!phoneNumber || !payItemId || !customerInfo) {
      return res.status(400).send({ error: 'Paramètres manquants: phoneNumber, payItemId, customerInfo sont requis.' });
    }

    const result = await mavianceService.purchaseVoucher(phoneNumber, payItemId, customerInfo);
    
    if (result.success) {
      res.status(200).send(result);
    } else {
      res.status(400).send(result);
    }
  } catch (error) {
    res.status(500).send({ error: 'Erreur lors de l\'achat du forfait', details: error.message });
  }
});

// Dépôt d'argent
app.post('/api/deposit', apiKeyAuth, async (req, res) => {
  try {
    const { amount, payItemId, customerInfo } = req.body;
    
    if (!amount || !payItemId || !customerInfo) {
      return res.status(400).send({ error: 'Paramètres manquants: amount, payItemId, customerInfo sont requis.' });
    }

    const result = await mavianceService.depositMoney(amount, payItemId, customerInfo);
    
    if (result.success) {
      res.status(200).send(result);
    } else {
      res.status(400).send(result);
    }
  } catch (error) {
    res.status(500).send({ error: 'Erreur lors du dépôt', details: error.message });
  }
});

// Retrait d'argent
app.post('/api/withdraw', apiKeyAuth, async (req, res) => {
  try {
    const { amount, payItemId, customerInfo } = req.body;
    
    if (!amount || !payItemId || !customerInfo) {
      return res.status(400).send({ error: 'Paramètres manquants: amount, payItemId, customerInfo sont requis.' });
    }

    const result = await mavianceService.withdrawMoney(amount, payItemId, customerInfo);
    
    if (result.success) {
      res.status(200).send(result);
    } else {
      res.status(400).send(result);
    }
  } catch (error) {
    res.status(500).send({ error: 'Erreur lors du retrait', details: error.message });
  }
});

// Vérifier une transaction
app.get('/api/verify/:transactionId', apiKeyAuth, async (req, res) => {
  try {
    const { transactionId } = req.params;
    
    if (!transactionId) {
      return res.status(400).send({ error: 'Transaction ID requis.' });
    }

    const result = await mavianceService.verifyTransaction(transactionId);
    res.status(200).send(result);
  } catch (error) {
    res.status(500).send({ error: 'Erreur lors de la vérification', details: error.message });
  }
});

// Récupérer les produits TOPUP pour un service donné
app.get('/api/topup/:serviceId', apiKeyAuth, async (req, res) => {
  try {
    const { serviceId } = req.params;
    const result = await mavianceService.getTopupProducts(serviceId);
    res.status(200).send(result);
  } catch (error) {
    res.status(500).send({ error: 'Erreur lors de la récupération des produits', details: error.message });
  }
});

// Récupérer les produits VOUCHER pour un service donné
app.get('/api/voucher/:serviceId', apiKeyAuth, async (req, res) => {
  try {
    const { serviceId } = req.params;
    const result = await mavianceService.getVoucherProducts(serviceId);
    res.status(200).send(result);
  } catch (error) {
    res.status(500).send({ error: 'Erreur lors de la récupération des forfaits', details: error.message });
  }
});

// Route spéciale pour l'achat de float (via passerelle USSD)
app.post('/api/float/purchase', apiKeyAuth, (req, res) => {
  const { phoneNumber, amount } = req.body;

  if (!phoneNumber || !amount) {
    return res.status(400).send({ error: 'Numéro et montant sont requis.' });
  }

  // TODO: Intégrer la logique d'appel à la passerelle USSD
  console.log(`Demande d\'achat de float de ${amount} XAF pour le ${phoneNumber}`);

  res.status(200).send({ message: 'Demande reçue. Traitement en cours...' });
});

// Routes CallBox - Utilisation des routes définies dans le fichier séparé
app.use('/api/call-box', callboxRoutes);

// Routes pour la gestion du service de synchronisation CallBox
app.get('/api/sync/status', apiKeyAuth, async (req, res) => {
  try {
    const status = await callboxSyncService.getSyncStatus();
    res.json({
      success: true,
      syncStatus: status
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération du statut',
      details: error.message
    });
  }
});

app.post('/api/sync/start', apiKeyAuth, (req, res) => {
  try {
    callboxSyncService.start();
    res.json({
      success: true,
      message: 'Service de synchronisation démarré'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Erreur lors du démarrage',
      details: error.message
    });
  }
});

app.post('/api/sync/stop', apiKeyAuth, (req, res) => {
  try {
    callboxSyncService.stop();
    res.json({
      success: true,
      message: 'Service de synchronisation arrêté'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Erreur lors de l\'arrêt',
      details: error.message
    });
  }
});

app.post('/api/sync/force', apiKeyAuth, async (req, res) => {
  try {
    await callboxSyncService.forcSync();
    res.json({
      success: true,
      message: 'Synchronisation forcée exécutée'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la synchronisation forcée',
      details: error.message
    });
  }
});

// Route pour intégrer les transactions du système principal vers CallBox
app.post('/api/transaction/to-callbox', apiKeyAuth, async (req, res) => {
  try {
    const result = await callboxSyncService.createTransactionFromSystem(req.body);
    res.json({
      success: true,
      message: 'Transaction envoyée au CallBox',
      transactionId: result.transactionId
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Erreur lors de l\'envoi au CallBox',
      details: error.message
    });
  }
});

// ===============================
// Routes d'administration
// ===============================

// Middleware spécifique pour l'administration avec logs de sécurité
const adminAuth = (req, res, next) => {
  const providedApiKey = req.headers['x-api-key'];
  if (!providedApiKey || providedApiKey !== API_KEY) {
    console.warn(`Admin access denied from ${req.ip} at ${new Date().toISOString()}`);
    return res.status(401).send({ error: 'Accès administrateur non autorisé.' });
  }
  console.log(`Admin access granted from ${req.ip} at ${new Date().toISOString()}`);
  next();
};

// Servir les fichiers statiques du dashboard admin
app.use('/admin', express.static('admin-dashboard'));

// Redirection vers la page de login admin
app.get('/admin-login', (req, res) => {
  res.redirect('/admin/login.html');
});

// Statistiques pour le dashboard admin
app.get('/api/admin/stats', adminAuth, async (req, res) => {
  try {
    // Générer des statistiques simulées
    // Dans un vrai projet, ces données viendraient d'une base de données
    const stats = {
      totalTransactions: Math.floor(Math.random() * 1000) + 500,
      todayTransactions: Math.floor(Math.random() * 150) + 50,
      successfulTransactions: Math.floor(Math.random() * 140) + 45,
      failedTransactions: Math.floor(Math.random() * 10) + 2,
      totalRevenue: Math.floor(Math.random() * 5000000) + 1000000,
      todayRevenue: Math.floor(Math.random() * 500000) + 100000,
      activeServices: Math.floor(Math.random() * 10) + 5,
      syncStatus: 'active',
      lastSync: new Date().toISOString(),
      systemUptime: Math.floor(Math.random() * 1000000) + 500000
    };
    
    res.json({
      success: true,
      data: stats,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des statistiques admin:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des statistiques',
      details: error.message
    });
  }
});

// Liste des transactions avec pagination pour l'admin
app.get('/api/admin/transactions', adminAuth, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const type = req.query.type;
    const status = req.query.status;
    const date = req.query.date;
    
    // Simuler des données de transaction
    let transactions = [];
    const types = ['recharge', 'voucher', 'deposit', 'withdraw'];
    const statuses = ['success', 'error', 'pending'];
    
    for (let i = 0; i < 100; i++) {
      transactions.push({
        id: `TXN${String(i + 1).padStart(6, '0')}`,
        type: types[Math.floor(Math.random() * types.length)],
        phoneNumber: `+237${Math.floor(Math.random() * 900000000) + 600000000}`,
        amount: Math.floor(Math.random() * 50000) + 1000,
        status: statuses[Math.floor(Math.random() * statuses.length)],
        customerInfo: {
          name: `Client ${i + 1}`,
          email: `client${i + 1}@example.com`
        },
        payItemId: Math.floor(Math.random() * 1000) + 1,
        date: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000),
        details: `Transaction ${i + 1} - Détails de la transaction`,
        commission: Math.floor(Math.random() * 1000) + 50
      });
    }
    
    // Filtrer par type si spécifié
    if (type) {
      transactions = transactions.filter(t => t.type === type);
    }
    
    // Filtrer par statut si spécifié
    if (status) {
      transactions = transactions.filter(t => t.status === status);
    }
    
    // Filtrer par date si spécifiée
    if (date) {
      const filterDate = new Date(date);
      transactions = transactions.filter(t => {
        const txDate = new Date(t.date);
        return txDate.toDateString() === filterDate.toDateString();
      });
    }
    
    // Trier par date décroissante
    transactions.sort((a, b) => new Date(b.date) - new Date(a.date));
    
    // Pagination
    const startIndex = (page - 1) * limit;
    const endIndex = startIndex + limit;
    const paginatedTransactions = transactions.slice(startIndex, endIndex);
    
    res.json({
      success: true,
      data: paginatedTransactions,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(transactions.length / limit),
        totalItems: transactions.length,
        itemsPerPage: limit
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des transactions admin:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des transactions',
      details: error.message
    });
  }
});

// Détails d'une transaction spécifique
app.get('/api/admin/transaction/:id', adminAuth, async (req, res) => {
  try {
    const transactionId = req.params.id;
    
    // Simuler la récupération d'une transaction
    const transaction = {
      id: transactionId,
      type: 'recharge',
      phoneNumber: '+237670123456',
      amount: 5000,
      status: 'success',
      customerInfo: {
        name: 'Client Test',
        email: 'client@example.com',
        phone: '+237670123456'
      },
      payItemId: 123,
      date: new Date(),
      details: 'Recharge de crédit mobile',
      commission: 250,
      mavianceReference: 'MAV123456',
      callboxReference: 'CBX789012',
      processingTime: '2.3s',
      ipAddress: req.ip,
      userAgent: req.get('User-Agent')
    };
    
    res.json({
      success: true,
      data: transaction,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des détails de transaction:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des détails',
      details: error.message
    });
  }
});

// Rapports pour une période donnée
app.get('/api/admin/reports', adminAuth, async (req, res) => {
  try {
    const startDate = req.query.startDate;
    const endDate = req.query.endDate;
    
    if (!startDate || !endDate) {
      return res.status(400).json({
        success: false,
        error: 'Les dates de début et de fin sont requises'
      });
    }
    
    const start = new Date(startDate);
    const end = new Date(endDate);
    const days = Math.ceil((end - start) / (1000 * 60 * 60 * 24));
    
    // Générer des données de rapport simulées
    const reportData = {
      summary: {
        totalTransactions: Math.floor(Math.random() * days * 50) + days * 20,
        totalRevenue: Math.floor(Math.random() * days * 100000) + days * 50000,
        averageTransactionValue: Math.floor(Math.random() * 5000) + 2500,
        successRate: (Math.random() * 10 + 90).toFixed(2) + '%',
        topService: 'MTN Cameroon',
        topTransactionType: 'Recharge'
      },
      dailyData: Array.from({length: days}, (_, i) => {
        const date = new Date(start.getTime() + i * 24 * 60 * 60 * 1000);
        return {
          date: date.toISOString().split('T')[0],
          transactions: Math.floor(Math.random() * 100) + 20,
          revenue: Math.floor(Math.random() * 200000) + 50000,
          successRate: (Math.random() * 10 + 90).toFixed(2)
        };
      }),
      typeBreakdown: {
        recharge: Math.floor(Math.random() * 40) + 30,
        voucher: Math.floor(Math.random() * 30) + 20,
        deposit: Math.floor(Math.random() * 20) + 10,
        withdraw: Math.floor(Math.random() * 15) + 5
      }
    };
    
    res.json({
      success: true,
      data: reportData,
      period: { startDate, endDate },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Erreur lors de la génération du rapport:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la génération du rapport',
      details: error.message
    });
  }
});

// Configuration système
app.get('/api/admin/config', adminAuth, (req, res) => {
  try {
    const config = {
      serverInfo: {
        version: '1.0.0',
        environment: process.env.NODE_ENV || 'development',
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        pid: process.pid
      },
      services: {
        maviance: {
          status: 'connected',
          lastPing: new Date().toISOString()
        },
        callbox: {
          status: 'active',
          lastSync: new Date().toISOString()
        }
      },
      security: {
        apiKeySet: !!API_KEY,
        httpsEnabled: req.secure || req.headers['x-forwarded-proto'] === 'https',
        corsEnabled: true
      }
    };
    
    res.json({
      success: true,
      data: config,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Erreur lors de la récupération de la configuration:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération de la configuration',
      details: error.message
    });
  }
});

// Mise à jour de la configuration (POST)
app.post('/api/admin/config', adminAuth, (req, res) => {
  try {
    const { apiKey, notifications } = req.body;
    
    // Dans un vrai projet, sauvegarder la configuration dans une base de données
    // ou un fichier de configuration sécurisé
    
    console.log('Configuration mise à jour par admin:', {
      apiKeyUpdated: !!apiKey,
      notificationsUpdated: !!notifications,
      timestamp: new Date().toISOString(),
      ip: req.ip
    });
    
    res.json({
      success: true,
      message: 'Configuration mise à jour avec succès',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Erreur lors de la mise à jour de la configuration:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la mise à jour de la configuration',
      details: error.message
    });
  }
});

// Logs système
app.get('/api/admin/logs', adminAuth, (req, res) => {
  try {
    const level = req.query.level || 'all';
    const limit = parseInt(req.query.limit) || 100;
    
    // Simuler des logs système
    const logs = [];
    const levels = ['INFO', 'WARNING', 'ERROR', 'DEBUG'];
    const messages = [
      'Transaction processed successfully',
      'Maviance service ping successful',
      'CallBox synchronization completed',
      'New admin session started',
      'Configuration updated',
      'Service restart detected',
      'High memory usage detected',
      'API rate limit exceeded',
      'Database connection restored',
      'Backup completed successfully'
    ];
    
    for (let i = 0; i < limit; i++) {
      const logLevel = levels[Math.floor(Math.random() * levels.length)];
      if (level !== 'all' && logLevel.toLowerCase() !== level.toLowerCase()) {
        continue;
      }
      
      logs.push({
        timestamp: new Date(Date.now() - Math.random() * 24 * 60 * 60 * 1000).toISOString(),
        level: logLevel,
        message: messages[Math.floor(Math.random() * messages.length)],
        source: 'merecharge-backend',
        details: `Log entry ${i + 1} with additional context`
      });
    }
    
    logs.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    
    res.json({
      success: true,
      data: logs.slice(0, limit),
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des logs:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des logs',
      details: error.message
    });
  }
});

app.listen(port, () => {
  console.log(`Serveur démarré sur http://localhost:${port}`);
  console.log(`Dashboard admin accessible sur http://localhost:${port}/admin`);
  
  // Démarrer le service de synchronisation CallBox
  setTimeout(() => {
    callboxSyncService.start();
    console.log('Service de synchronisation CallBox démarré automatiquement');
  }, 2000); // Délai de 2 secondes pour permettre au serveur de démarrer complètement
});
