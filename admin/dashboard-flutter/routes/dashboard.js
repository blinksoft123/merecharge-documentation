const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const { User, Transaction, Service } = require('../models');
const { Op } = require('sequelize');

router.use(requireAuth);

// Route du dashboard avec vraies données
router.get('/', async (req, res) => {
  try {
    // Récupérer tous les services
    const services = await Service.findAll({
      order: [['displayName', 'ASC']]
    });

    // Récupérer les statistiques générales
    const totalUsers = await User.count({ where: { isActive: true } });
    const totalTransactions = await Transaction.count();
    const totalRevenue = await Transaction.sum('totalAmount', {
      where: { status: 'success' }
    }) || 0;
    const pendingTransactions = await Transaction.count({
      where: { status: ['pending', 'processing'] }
    });

    // Récupérer les transactions récentes avec les services associés
    const recentTransactions = await Transaction.findAll({
      limit: 5,
      order: [['createdAt', 'DESC']],
      include: [{
        model: Service,
        as: 'service',
        attributes: ['name', 'displayName', 'icon', 'color']
      }]
    });

    // Récupérer les utilisateurs avec leurs soldes
    const recentUsers = await User.findAll({
      limit: 5,
      order: [['lastLoginAt', 'DESC']],
      where: {
        lastLoginAt: {
          [Op.not]: null
        }
      },
      attributes: ['id', 'firstName', 'lastName', 'phone', 'balance', 'status', 'lastLoginAt']
    });

    // Calculer le solde total de tous les utilisateurs
    const totalUserBalance = await User.sum('balance') || 0;

    res.render('dashboard/index', {
      title: 'Dashboard - MeRecharge Admin',
      user: req.session.user,
      services: services,
      stats: {
        totalUsers,
        totalTransactions,
        totalRevenue: parseFloat(totalRevenue),
        pendingTransactions,
        totalUserBalance: parseFloat(totalUserBalance)
      },
      recentTransactions,
      recentUsers
    });
  } catch (error) {
    console.error('Erreur dashboard:', error);
    res.render('error', {
      title: 'Erreur',
      message: 'Impossible de charger le dashboard'
    });
  }
});

// Route pour activer/désactiver un service
router.post('/service/:id/toggle', async (req, res) => {
  try {
    const service = await Service.findByPk(req.params.id);
    if (!service) {
      return res.status(404).json({ success: false, message: 'Service non trouvé' });
    }

    service.isActive = !service.isActive;
    await service.save();

    res.json({
      success: true,
      message: `Service ${service.isActive ? 'activé' : 'désactivé'} avec succès`,
      isActive: service.isActive
    });
  } catch (error) {
    console.error('Erreur toggle service:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
});

module.exports = router;