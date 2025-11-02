const { sequelize } = require('../config/database');
const Service = require('./Service');
const Transaction = require('./Transaction');
const User = require('./User');

// Configuration des relations
Service.hasMany(Transaction, {
  foreignKey: 'serviceId',
  as: 'transactions',
});

Transaction.belongsTo(Service, {
  foreignKey: 'serviceId',
  as: 'service',
});

User.hasMany(Transaction, {
  foreignKey: 'userPhone',
  sourceKey: 'phone',
  as: 'transactions',
});

Transaction.belongsTo(User, {
  foreignKey: 'userPhone',
  targetKey: 'phone',
  as: 'user',
});

// Fonction pour synchroniser la base de données
async function syncDatabase() {
  try {
    await sequelize.sync({ alter: true });
    console.log('✅ Base de données synchronisée');
    await seedDatabase();
  } catch (error) {
    console.error('❌ Erreur lors de la synchronisation:', error);
  }
}

// Données de test pour peupler la base
async function seedDatabase() {
  try {
    // Vérifier si des services existent déjà
    const servicesCount = await Service.count();
    if (servicesCount > 0) {
      console.log('ℹ️ Services déjà présents dans la base');
      return;
    }

    // Créer les services par défaut
    const services = [
      {
        name: 'orange_credit',
        displayName: 'Orange Crédit',
        description: 'Recharge de crédit Orange',
        icon: 'fas fa-mobile-alt',
        color: 'orange',
        serviceType: 'topup',
        provider: 'Orange',
        minAmount: 100,
        maxAmount: 50000,
        fees: 0.02,
        isActive: true,
      },
      {
        name: 'mtn_data',
        displayName: 'MTN Data Bundle',
        description: 'Forfaits internet MTN',
        icon: 'fas fa-wifi',
        color: 'green',
        serviceType: 'data',
        provider: 'MTN',
        minAmount: 500,
        maxAmount: 20000,
        fees: 0.015,
        isActive: true,
      },
      {
        name: 'moov_money',
        displayName: 'Moov Money',
        description: 'Transfert d\'argent Moov',
        icon: 'fas fa-money-bill-wave',
        color: 'blue',
        serviceType: 'transfer',
        provider: 'Moov',
        minAmount: 500,
        maxAmount: 100000,
        fees: 0.025,
        isActive: true,
      },
      {
        name: 'camtel_bills',
        displayName: 'Camtel Factures',
        description: 'Paiement factures Camtel',
        icon: 'fas fa-phone',
        color: 'purple',
        serviceType: 'bill',
        provider: 'Camtel',
        minAmount: 1000,
        maxAmount: 100000,
        fees: 0.01,
        isActive: true,
      },
      {
        name: 'eneo_bills',
        displayName: 'ENEO Électricité',
        description: 'Paiement factures d\'électricité',
        icon: 'fas fa-bolt',
        color: 'yellow',
        serviceType: 'bill',
        provider: 'ENEO',
        minAmount: 1000,
        maxAmount: 200000,
        fees: 0.01,
        isActive: true,
      },
      {
        name: 'canal_plus',
        displayName: 'Canal+ Abonnement',
        description: 'Abonnement Canal+',
        icon: 'fas fa-tv',
        color: 'red',
        serviceType: 'subscription',
        provider: 'Canal+',
        minAmount: 5000,
        maxAmount: 30000,
        fees: 0.015,
        isActive: false, // Désactivé par défaut
      },
      {
        name: 'express_union',
        displayName: 'Express Union',
        description: 'Services bancaires Express Union',
        icon: 'fas fa-university',
        color: 'indigo',
        serviceType: 'transfer',
        provider: 'Express Union',
        minAmount: 1000,
        maxAmount: 500000,
        fees: 0.02,
        isActive: true,
      },
    ];

    await Service.bulkCreate(services);
    console.log('✅ Services initiaux créés');

    // Créer quelques utilisateurs de test avec des balances réalistes
    const users = [
      {
        phone: '+237678901234',
        email: 'pierre.kamga@email.com',
        firstName: 'Pierre',
        lastName: 'Kamga',
        balance: 125000.75, // 125,000.75 FCFA
        status: 'active',
        isActive: true,
        lastLoginAt: new Date(),
      },
      {
        phone: '+237699123456',
        email: 'marie.fouda@email.com',
        firstName: 'Marie',
        lastName: 'Fouda',
        balance: 67500.00, // 67,500 FCFA
        status: 'active',
        isActive: true,
        lastLoginAt: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2h ago
      },
      {
        phone: '+237690789012',
        email: 'jean.baptiste@email.com',
        firstName: 'Jean',
        lastName: 'Baptiste',
        balance: 15800.50, // 15,800.50 FCFA
        status: 'active',
        isActive: true,
        lastLoginAt: new Date(Date.now() - 6 * 60 * 60 * 1000), // 6h ago
      },
      {
        phone: '+237682123456',
        email: 'fatima.ngono@example.com',
        firstName: 'Fatima',
        lastName: 'Ngono',
        balance: 245890.25, // 245,890.25 FCFA
        status: 'active',
        isActive: true,
        lastLoginAt: new Date(Date.now() - 45 * 60 * 1000), // 45 min ago
      },
      {
        phone: '+237655444333',
        email: 'paul.martin@example.com',
        firstName: 'Paul',
        lastName: 'Martin',
        balance: 8750.00, // 8,750 FCFA
        status: 'suspended',
        isActive: false,
        lastLoginAt: new Date(Date.now() - 24 * 60 * 60 * 1000), // 1 day ago
      },
    ];

    await User.bulkCreate(users);
    console.log('✅ Utilisateurs de test créés');

    // Créer quelques transactions de test
    const createdServices = await Service.findAll();
    const transactions = [];
    
    // Générer des transactions de test pour les 30 derniers jours
    for (let i = 0; i < 50; i++) {
      const randomService = createdServices[Math.floor(Math.random() * createdServices.length)];
      const randomUser = users[Math.floor(Math.random() * users.length)];
      const randomAmount = Math.floor(Math.random() * 50000) + 500;
      const fees = Math.floor(randomAmount * parseFloat(randomService.fees));
      const randomDate = new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000); // 30 derniers jours
      const statuses = ['success', 'pending', 'failed', 'processing'];
      const randomStatus = statuses[Math.floor(Math.random() * statuses.length)];
      
      transactions.push({
        transactionId: `TXN${String(Date.now() + i).slice(-8)}`,
        referenceId: `REF${String(Date.now() + i).slice(-10)}`,
        serviceId: randomService.id,
        userPhone: randomUser.phone,
        recipientPhone: `+237${Math.floor(Math.random() * 900000000) + 600000000}`,
        amount: randomAmount,
        fees: fees,
        totalAmount: randomAmount + fees,
        status: randomStatus,
        mavianceReference: randomStatus !== 'failed' ? `MAV${Date.now() + i}` : null,
        errorMessage: randomStatus === 'failed' ? 'Insufficient balance' : null,
        processedAt: randomStatus !== 'pending' ? randomDate : null,
        completedAt: randomStatus === 'success' ? randomDate : null,
        createdAt: randomDate,
        updatedAt: randomDate,
      });
    }
    
    await Transaction.bulkCreate(transactions);
    console.log('✅ Transactions de test créées');

    // Mettre à jour les statistiques des services
    for (const service of createdServices) {
      const serviceTransactions = transactions.filter(t => t.serviceId === service.id);
      const successfulTransactions = serviceTransactions.filter(t => t.status === 'success');
      
      await service.update({
        totalTransactions: serviceTransactions.length,
        totalRevenue: successfulTransactions.reduce((sum, t) => sum + t.amount, 0),
        lastUsed: serviceTransactions.length > 0 ? Math.max(...serviceTransactions.map(t => t.createdAt)) : null
      });
    }
    
    console.log('✅ Statistiques des services mises à jour');

  } catch (error) {
    console.error('❌ Erreur lors du peuplement:', error);
  }
}

module.exports = {
  sequelize,
  Service,
  Transaction,
  User,
  syncDatabase,
};