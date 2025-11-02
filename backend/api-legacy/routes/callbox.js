const express = require('express');
const router = express.Router();

// Simuler une base de données en mémoire pour les transactions
let transactionQueue = [];
let callboxInstances = new Map(); // Map pour stocker les instances CallBox connectées
let transactionHistory = [];
let callboxConfig = {
    maxRetries: 3,
    timeoutMs: 30000,
    batchSize: 5,
    pollIntervalMs: 5000
};

// Middleware pour l'authentification CallBox
const callboxAuth = (req, res, next) => {
    const token = req.headers['authorization']?.replace('Bearer ', '');
    if (!token || token !== process.env.CALLBOX_TOKEN || 'callbox-secure-token-2024') {
        return res.status(401).json({ error: 'Token d\'authentification CallBox invalide' });
    }
    next();
};

// Route pour l'enregistrement d'une instance CallBox
router.post('/register', callboxAuth, (req, res) => {
    const { callboxId, capabilities, version, location } = req.body;
    
    if (!callboxId) {
        return res.status(400).json({ error: 'callboxId requis' });
    }
    
    const instance = {
        id: callboxId,
        capabilities: capabilities || {},
        version: version || '1.0.0',
        location: location || 'unknown',
        lastHeartbeat: new Date(),
        status: 'active',
        queueSize: 0,
        processedTransactions: 0
    };
    
    callboxInstances.set(callboxId, instance);
    
    console.log(`CallBox ${callboxId} enregistré avec succès`);
    
    res.json({
        success: true,
        message: 'CallBox enregistré avec succès',
        config: callboxConfig,
        instance: instance
    });
});

// Route pour le heartbeat des CallBox
router.post('/heartbeat', callboxAuth, (req, res) => {
    const { callboxId, status, queueSize, metrics } = req.body;
    
    if (!callboxId) {
        return res.status(400).json({ error: 'callboxId requis' });
    }
    
    const instance = callboxInstances.get(callboxId);
    if (!instance) {
        return res.status(404).json({ error: 'CallBox non trouvé. Veuillez vous enregistrer d\'abord.' });
    }
    
    // Mettre à jour les informations de l'instance
    instance.lastHeartbeat = new Date();
    instance.status = status || instance.status;
    instance.queueSize = queueSize || instance.queueSize;
    if (metrics) {
        instance.metrics = { ...instance.metrics, ...metrics };
    }
    
    callboxInstances.set(callboxId, instance);
    
    res.json({
        success: true,
        message: 'Heartbeat reçu',
        pendingTransactions: transactionQueue.length,
        config: callboxConfig
    });
});

// Route pour récupérer les transactions en attente
router.get('/transactions/pending', callboxAuth, (req, res) => {
    const { callboxId, limit = 5 } = req.query;
    
    if (!callboxId) {
        return res.status(400).json({ error: 'callboxId requis' });
    }
    
    const instance = callboxInstances.get(callboxId);
    if (!instance) {
        return res.status(404).json({ error: 'CallBox non trouvé' });
    }
    
    // Récupérer les transactions en attente selon la limite
    const pendingTransactions = transactionQueue
        .filter(t => t.status === 'pending' && (!t.assignedTo || t.assignedTo === callboxId))
        .slice(0, parseInt(limit));
    
    // Assigner les transactions au CallBox
    pendingTransactions.forEach(transaction => {
        transaction.assignedTo = callboxId;
        transaction.assignedAt = new Date();
        transaction.status = 'assigned';
    });
    
    res.json({
        success: true,
        transactions: pendingTransactions,
        count: pendingTransactions.length,
        totalPending: transactionQueue.filter(t => t.status === 'pending').length
    });
});

// Route pour soumettre une nouvelle transaction à la queue
router.post('/transactions/submit', callboxAuth, (req, res) => {
    const { type, phoneNumber, amount, payItemId, customerInfo, priority = 'normal' } = req.body;
    
    if (!type || !phoneNumber) {
        return res.status(400).json({ 
            error: 'Type de transaction et numéro de téléphone requis' 
        });
    }
    
    const transaction = {
        id: `tx_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        type: type, // 'recharge', 'voucher', 'deposit', 'withdraw'
        phoneNumber: phoneNumber,
        amount: amount,
        payItemId: payItemId,
        customerInfo: customerInfo || {},
        priority: priority,
        status: 'pending',
        createdAt: new Date(),
        updatedAt: new Date(),
        retryCount: 0,
        maxRetries: callboxConfig.maxRetries
    };
    
    // Ajouter à la queue selon la priorité
    if (priority === 'high') {
        transactionQueue.unshift(transaction);
    } else {
        transactionQueue.push(transaction);
    }
    
    console.log(`Nouvelle transaction ajoutée: ${transaction.id} (${type})`);
    
    res.json({
        success: true,
        message: 'Transaction ajoutée à la queue',
        transactionId: transaction.id,
        queuePosition: transactionQueue.indexOf(transaction) + 1
    });
});

// Route pour mettre à jour le statut d'une transaction
router.put('/transactions/:transactionId/status', callboxAuth, (req, res) => {
    const { transactionId } = req.params;
    const { status, result, errorMessage, callboxId } = req.body;
    
    if (!status) {
        return res.status(400).json({ error: 'Statut requis' });
    }
    
    const transactionIndex = transactionQueue.findIndex(t => t.id === transactionId);
    if (transactionIndex === -1) {
        return res.status(404).json({ error: 'Transaction non trouvée' });
    }
    
    const transaction = transactionQueue[transactionIndex];
    
    // Vérifier si le CallBox a le droit de modifier cette transaction
    if (transaction.assignedTo && transaction.assignedTo !== callboxId) {
        return res.status(403).json({ error: 'Transaction assignée à un autre CallBox' });
    }
    
    // Mettre à jour la transaction
    transaction.status = status;
    transaction.updatedAt = new Date();
    transaction.processedBy = callboxId;
    
    if (result) {
        transaction.result = result;
    }
    
    if (errorMessage) {
        transaction.errorMessage = errorMessage;
    }
    
    // Si la transaction est terminée (succès ou échec final), la déplacer vers l'historique
    if (status === 'completed' || status === 'failed') {
        transactionHistory.push({ ...transaction });
        transactionQueue.splice(transactionIndex, 1);
        
        // Mettre à jour les statistiques du CallBox
        const instance = callboxInstances.get(callboxId);
        if (instance) {
            instance.processedTransactions += 1;
            instance.queueSize = Math.max(0, instance.queueSize - 1);
            callboxInstances.set(callboxId, instance);
        }
    } else if (status === 'retry') {
        transaction.retryCount += 1;
        if (transaction.retryCount >= transaction.maxRetries) {
            transaction.status = 'failed';
            transaction.errorMessage = 'Nombre maximum de tentatives atteint';
            transactionHistory.push({ ...transaction });
            transactionQueue.splice(transactionIndex, 1);
        } else {
            transaction.status = 'pending';
            transaction.assignedTo = null; // Libérer pour réassignation
        }
    }
    
    console.log(`Transaction ${transactionId} mise à jour: ${status}`);
    
    res.json({
        success: true,
        message: 'Statut de transaction mis à jour',
        transaction: {
            id: transaction.id,
            status: transaction.status,
            updatedAt: transaction.updatedAt
        }
    });
});

// Route pour récupérer la configuration du CallBox
router.get('/config', callboxAuth, (req, res) => {
    const { callboxId } = req.query;
    
    // Configuration personnalisée par CallBox si nécessaire
    const config = {
        ...callboxConfig,
        callboxSpecific: callboxInstances.get(callboxId)?.config || {}
    };
    
    res.json({
        success: true,
        config: config
    });
});

// Route pour mettre à jour la configuration
router.put('/config', callboxAuth, (req, res) => {
    const { maxRetries, timeoutMs, batchSize, pollIntervalMs } = req.body;
    
    if (maxRetries) callboxConfig.maxRetries = maxRetries;
    if (timeoutMs) callboxConfig.timeoutMs = timeoutMs;
    if (batchSize) callboxConfig.batchSize = batchSize;
    if (pollIntervalMs) callboxConfig.pollIntervalMs = pollIntervalMs;
    
    console.log('Configuration CallBox mise à jour:', callboxConfig);
    
    res.json({
        success: true,
        message: 'Configuration mise à jour',
        config: callboxConfig
    });
});

// Route pour obtenir les statistiques des CallBox
router.get('/stats', callboxAuth, (req, res) => {
    const stats = {
        connectedInstances: callboxInstances.size,
        queueLength: transactionQueue.length,
        pendingTransactions: transactionQueue.filter(t => t.status === 'pending').length,
        assignedTransactions: transactionQueue.filter(t => t.status === 'assigned').length,
        processingTransactions: transactionQueue.filter(t => t.status === 'processing').length,
        completedTransactions: transactionHistory.filter(t => t.status === 'completed').length,
        failedTransactions: transactionHistory.filter(t => t.status === 'failed').length,
        instances: Array.from(callboxInstances.values()).map(instance => ({
            id: instance.id,
            status: instance.status,
            lastHeartbeat: instance.lastHeartbeat,
            queueSize: instance.queueSize,
            processedTransactions: instance.processedTransactions
        }))
    };
    
    res.json({
        success: true,
        stats: stats
    });
});

// Route pour vider la queue (utile pour les tests)
router.delete('/transactions/clear', callboxAuth, (req, res) => {
    const beforeCount = transactionQueue.length;
    transactionQueue = [];
    
    res.json({
        success: true,
        message: `${beforeCount} transactions supprimées de la queue`
    });
});

// Route pour obtenir l'historique des transactions
router.get('/transactions/history', callboxAuth, (req, res) => {
    const { limit = 50, status, callboxId } = req.query;
    
    let filteredHistory = transactionHistory;
    
    if (status) {
        filteredHistory = filteredHistory.filter(t => t.status === status);
    }
    
    if (callboxId) {
        filteredHistory = filteredHistory.filter(t => t.processedBy === callboxId);
    }
    
    const paginatedHistory = filteredHistory
        .sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt))
        .slice(0, parseInt(limit));
    
    res.json({
        success: true,
        transactions: paginatedHistory,
        count: paginatedHistory.length,
        totalHistory: transactionHistory.length
    });
});

module.exports = router;