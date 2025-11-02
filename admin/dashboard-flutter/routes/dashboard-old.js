const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const { Service, Transaction, User } = require('../models');

// Middleware pour protéger toutes les routes du dashboard
router.use(requireAuth);

// Données simulées pour les statistiques
// En production, ces données viendraient de votre base de données
const getDashboardStats = () => {
  return {
    totalUsers: 1245,
    totalTransactions: 8967,
    todayRevenue: 125000,
    pendingTransactions: 23,
    
    // Données pour les graphiques
    monthlyTransactions: [
      { month: 'Jan', count: 450 },
      { month: 'Fév', count: 520 },
      { month: 'Mar', count: 680 },
      { month: 'Avr', count: 590 },
      { month: 'Mai', count: 720 },
      { month: 'Jun', count: 890 }
    ],
    
    transactionsByType: [
      { type: 'Recharge', count: 3500, color: '#4BA3F2' },
      { type: 'Forfaits', count: 2800, color: '#28a745' },
      { type: 'Transferts', count: 1900, color: '#ffc107' },
      { type: 'Retraits', count: 767, color: '#dc3545' }
    ],
    
    recentTransactions: [
      {
        id: 'TX123456',
        user: 'Jean Dupont',
        phone: '699123456',
        type: 'Recharge',
        amount: 5000,
        status: 'success',
        date: new Date()
      },
      {
        id: 'TX123457',
        user: 'Marie Claire',
        phone: '677987654',
        type: 'Forfait',
        amount: 2000,
        status: 'pending',
        date: new Date(Date.now() - 5 * 60 * 1000)
      },
      {
        id: 'TX123458',
        user: 'Paul Martin',
        phone: '655444333',
        type: 'Transfert',
        amount: 10000,
        status: 'failed',
        date: new Date(Date.now() - 10 * 60 * 1000)
      }
    ]
  };
};

// Page principale du dashboard
router.get('/', (req, res) => {
  const stats = getDashboardStats();
  
  res.render('dashboard/index', {
    title: 'Tableau de bord',
    stats: stats
  });
});

// API pour récupérer les statistiques en temps réel
router.get('/api/stats', (req, res) => {
  const stats = getDashboardStats();
  res.json(stats);
});

// API pour les données des graphiques
router.get('/api/charts/transactions', (req, res) => {
  const stats = getDashboardStats();
  res.json({
    monthly: stats.monthlyTransactions,
    byType: stats.transactionsByType
  });
});

module.exports = router;