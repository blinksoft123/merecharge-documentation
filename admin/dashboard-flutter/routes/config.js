const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);

// Page de configuration
router.get('/', (req, res) => {
  const config = {
    api: {
      s3p_key: process.env.S3P_KEY || 'ef63c4bf-3651-49da-870f-60332ac14796',
      base_url: process.env.MAVIANCE_BASE_URL || 'https://s3pv2cm.smobilpay.com/v2',
      timeout: 30000
    },
    app: {
      name: 'MeRecharge',
      version: '1.0.0',
      maintenance_mode: false
    },
    notifications: {
      email_enabled: true,
      sms_enabled: false
    },
    fees: {
      transaction_fee: 0.02, // 2%
      min_fee: 50, // FCFA
      max_fee: 1000 // FCFA
    }
  };

  res.render('config/index', {
    title: 'Configuration système',
    user: req.session.user,
    config: config
  });
});

// Sauvegarder la configuration API
router.post('/api', (req, res) => {
  const { base_url, timeout } = req.body;
  
  // Ici, vous sauvegarderez dans un fichier de config ou base de données
  console.log('Sauvegarde config API:', { base_url, timeout });
  
  res.json({ 
    success: true, 
    message: 'Configuration API sauvegardée avec succès' 
  });
});

// Sauvegarder la configuration application
router.post('/app', (req, res) => {
  const { name, version, maintenance_mode } = req.body;
  
  console.log('Sauvegarde config app:', { name, version, maintenance_mode });
  
  res.json({ 
    success: true, 
    message: 'Configuration application sauvegardée avec succès' 
  });
});

// Sauvegarder la configuration des frais
router.post('/fees', (req, res) => {
  const { transaction_fee, min_fee, max_fee } = req.body;
  
  console.log('Sauvegarde config frais:', { transaction_fee, min_fee, max_fee });
  
  res.json({ 
    success: true, 
    message: 'Configuration des frais sauvegardée avec succès' 
  });
});

// Sauvegarder la configuration des notifications
router.post('/notifications', (req, res) => {
  const { email_enabled, sms_enabled } = req.body;
  
  console.log('Sauvegarde config notifications:', { email_enabled, sms_enabled });
  
  res.json({ 
    success: true, 
    message: 'Configuration des notifications sauvegardée avec succès' 
  });
});

// Tester la connexion API
router.post('/test-api', async (req, res) => {
  try {
    // Ici vous testeriez la vraie connexion à l'API Maviance
    // Pour l'instant, on simule
    const isConnected = Math.random() > 0.2; // 80% de chance de succès
    
    if (isConnected) {
      res.json({ 
        success: true, 
        message: 'Connexion API réussie',
        response_time: Math.floor(Math.random() * 500) + 100 // 100-600ms
      });
    } else {
      res.status(500).json({ 
        success: false, 
        message: 'Impossible de se connecter à l\'API Maviance' 
      });
    }
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: 'Erreur lors du test de connexion: ' + error.message 
    });
  }
});

// Actions rapides
router.post('/clear-cache', (req, res) => {
  // Simuler le vidage du cache
  console.log('Cache vidé');
  res.json({ success: true, message: 'Cache vidé avec succès' });
});

router.post('/restart-service', (req, res) => {
  // Simuler le redémarrage du service
  console.log('Service redémarré');
  res.json({ success: true, message: 'Service redémarré avec succès' });
});

module.exports = router;