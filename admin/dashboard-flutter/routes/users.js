const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const { User, Transaction, Service } = require('../models');
const { Op } = require('sequelize');

router.use(requireAuth);

// Liste des utilisateurs
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const search = req.query.search || '';
    
    // Construire les conditions de recherche
    const whereClause = {};
    if (search) {
      whereClause[Op.or] = [
        { name: { [Op.like]: `%${search}%` } },
        { email: { [Op.like]: `%${search}%` } },
        { phone: { [Op.like]: `%${search}%` } }
      ];
    }
    
    // Récupérer les utilisateurs avec pagination
    const { count, rows: users } = await User.findAndCountAll({
      where: whereClause,
      limit: limit,
      offset: (page - 1) * limit,
      order: [['createdAt', 'DESC']],
      include: [
        {
          model: Transaction,
          as: 'transactions',
          attributes: ['amount', 'status'],
          required: false
        }
      ]
    });
    
    // Calculer les statistiques pour chaque utilisateur
    const usersWithStats = users.map(user => {
      const userTransactions = user.transactions || [];
      const totalTransactions = userTransactions.length;
      const totalSpent = userTransactions
        .filter(t => t.status === 'success')
        .reduce((sum, t) => sum + t.amount, 0);
      
      return {
        ...user.toJSON(),
        totalTransactions,
        totalSpent,
        registrationDate: user.createdAt,
        lastActivity: user.updatedAt
      };
    });
    
    res.render('users/index', {
      title: 'Gestion des utilisateurs',
      users: usersWithStats,
      totalUsers: count,
      currentPage: page,
      totalPages: Math.ceil(count / limit),
      search: search
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des utilisateurs:', error);
    res.render('users/index', {
      title: 'Gestion des utilisateurs',
      users: [],
      totalUsers: 0,
      currentPage: 1,
      totalPages: 1,
      search: '',
      error: 'Impossible de charger les utilisateurs'
    });
  }
});

// Détails d'un utilisateur
router.get('/:id', async (req, res) => {
  try {
    const userId = parseInt(req.params.id);
    
    // Récupérer l'utilisateur avec ses transactions
    const user = await User.findByPk(userId, {
      include: [
        {
          model: Transaction,
          as: 'transactions',
          include: [
            {
              model: Service,
              as: 'service',
              attributes: ['name', 'serviceType', 'provider']
            }
          ],
          order: [['createdAt', 'DESC']],
          limit: 20 // Limiter aux 20 dernières transactions
        }
      ]
    });
    
    if (!user) {
      return res.status(404).render('404', {
        title: 'Utilisateur non trouvé',
        message: 'Cet utilisateur n\'existe pas.'
      });
    }
    
    // Formater les transactions pour l'affichage
    const userTransactions = user.transactions.map(transaction => ({
      id: transaction.transactionId,
      type: transaction.service ? transaction.service.name : 'Service inconnu',
      operator: transaction.service ? transaction.service.provider : 'N/A',
      amount: transaction.amount,
      fees: transaction.fees,
      status: transaction.status,
      date: transaction.createdAt,
      referenceId: transaction.referenceId,
      recipientPhone: transaction.recipientPhone,
      mavianceReference: transaction.mavianceReference,
      errorMessage: transaction.errorMessage
    }));
    
    // Calculer les statistiques de l'utilisateur
    const totalTransactions = user.transactions.length;
    const successfulTransactions = user.transactions.filter(t => t.status === 'success');
    const totalSpent = successfulTransactions.reduce((sum, t) => sum + t.amount, 0);
    const totalFees = successfulTransactions.reduce((sum, t) => sum + t.fees, 0);
    
    res.render('users/detail', {
      title: `Utilisateur: ${user.name}`,
      user: {
        ...user.toJSON(),
        totalTransactions,
        totalSpent,
        totalFees,
        registrationDate: user.createdAt,
        lastActivity: user.updatedAt
      },
      transactions: userTransactions
    });
  } catch (error) {
    console.error('Erreur lors de la récupération de l\'utilisateur:', error);
    res.status(500).render('500', {
      title: 'Erreur serveur',
      message: 'Impossible de charger les détails de l\'utilisateur'
    });
  }
});

// Suspendre/Activer un utilisateur
router.post('/:id/toggle-status', async (req, res) => {
  try {
    const userId = parseInt(req.params.id);
    
    // Récupérer l'utilisateur
    const user = await User.findByPk(userId);
    
    if (!user) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }
    
    // Basculer le statut
    const newStatus = user.status === 'active' ? 'suspended' : 'active';
    await user.update({ status: newStatus });
    
    res.json({
      success: true,
      newStatus: newStatus,
      message: `Utilisateur ${newStatus === 'active' ? 'activé' : 'suspendu'} avec succès`
    });
  } catch (error) {
    console.error('Erreur lors de la modification du statut:', error);
    res.status(500).json({ 
      error: 'Erreur serveur',
      message: 'Impossible de modifier le statut de l\'utilisateur'
    });
  }
});

module.exports = router;