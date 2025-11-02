const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const { Transaction, User, Service } = require('../models');
const { Op } = require('sequelize');

router.use(requireAuth);

// Page des transactions avec pagination et filtres
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const status = req.query.status || '';
    const service = req.query.service || '';
    const search = req.query.search || '';
    const dateFrom = req.query.date_from || '';
    const dateTo = req.query.date_to || '';
    
    // Construire les conditions de recherche
    const whereClause = {};
    
    if (status) {
      whereClause.status = status;
    }
    
    if (search) {
      whereClause[Op.or] = [
        { transactionId: { [Op.like]: `%${search}%` } },
        { referenceId: { [Op.like]: `%${search}%` } },
        { userPhone: { [Op.like]: `%${search}%` } },
        { recipientPhone: { [Op.like]: `%${search}%` } }
      ];
    }
    
    if (dateFrom) {
      whereClause.createdAt = {
        [Op.gte]: new Date(dateFrom)
      };
    }
    
    if (dateTo) {
      const toDate = new Date(dateTo);
      toDate.setHours(23, 59, 59, 999);
      
      if (whereClause.createdAt) {
        whereClause.createdAt[Op.lte] = toDate;
      } else {
        whereClause.createdAt = {
          [Op.lte]: toDate
        };
      }
    }
    
    // Ajouter le filtre par service si nécessaire
    const includeClause = [
      {
        model: Service,
        as: 'service',
        where: service ? { name: service } : {},
        required: !!service
      },
      {
        model: User,
        as: 'user',
        required: false,
        attributes: ['id', 'name', 'email']
      }
    ];
    
    // Récupérer les transactions avec pagination
    const { count, rows: transactions } = await Transaction.findAndCountAll({
      where: whereClause,
      include: includeClause,
      limit: limit,
      offset: (page - 1) * limit,
      order: [['createdAt', 'DESC']]
    });
    
    // Formater les transactions pour l'affichage
    const formattedTransactions = transactions.map(transaction => ({
      id: transaction.transactionId,
      reference: transaction.referenceId,
      user_phone: transaction.userPhone,
      service: transaction.service ? transaction.service.name : 'Service inconnu',
      operator: transaction.service ? transaction.service.provider : 'N/A',
      amount: transaction.amount,
      fees: transaction.fees,
      total: transaction.totalAmount,
      status: transaction.status.toUpperCase(),
      recipient_phone: transaction.recipientPhone,
      created_at: transaction.createdAt,
      updated_at: transaction.updatedAt,
      maviance_reference: transaction.mavianceReference,
      error_message: transaction.errorMessage,
      user: transaction.user
    }));
    
    // Calculer les statistiques rapides
    const allTransactions = await Transaction.findAll({
      where: whereClause,
      include: service ? [{ model: Service, as: 'service', where: { name: service } }] : []
    });
    
    const stats = {
      total_count: count,
      total_amount: allTransactions.reduce((sum, t) => sum + t.amount, 0),
      total_fees: allTransactions.reduce((sum, t) => sum + t.fees, 0),
      success_count: allTransactions.filter(t => t.status === 'success').length,
      pending_count: allTransactions.filter(t => t.status === 'pending').length,
      failed_count: allTransactions.filter(t => t.status === 'failed').length
    };
    
    // Récupérer la liste des services pour les filtres
    const services = await Service.findAll({
      attributes: ['name'],
      group: ['name'],
      order: [['name', 'ASC']]
    });
    
    res.render('transactions/index', {
      title: 'Gestion des transactions',
      user: req.session.user,
      transactions: formattedTransactions,
      stats: stats,
      services: services.map(s => s.name),
      pagination: {
        current_page: page,
        per_page: limit,
        total_pages: Math.ceil(count / limit),
        total_records: count,
        has_prev: page > 1,
        has_next: page < Math.ceil(count / limit)
      },
      filters: {
        status: status,
        service: service,
        search: search,
        date_from: dateFrom,
        date_to: dateTo
      }
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des transactions:', error);
    res.render('transactions/index', {
      title: 'Gestion des transactions',
      user: req.session.user,
      transactions: [],
      stats: {
        total_count: 0,
        total_amount: 0,
        total_fees: 0,
        success_count: 0,
        pending_count: 0,
        failed_count: 0
      },
      services: [],
      pagination: {
        current_page: 1,
        per_page: 10,
        total_pages: 1,
        total_records: 0,
        has_prev: false,
        has_next: false
      },
      filters: {
        status: '',
        service: '',
        search: '',
        date_from: '',
        date_to: ''
      },
      error: 'Impossible de charger les transactions'
    });
  }
});

module.exports = router;