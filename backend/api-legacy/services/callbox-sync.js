const axios = require('axios');

class CallBoxSyncService {
    constructor(baseUrl = 'http://localhost:3000', callboxToken = 'callbox-secure-token-2024') {
        this.baseUrl = baseUrl;
        this.callboxToken = callboxToken;
        this.isRunning = false;
        this.syncInterval = null;
        this.syncIntervalMs = 10000; // 10 secondes par défaut
        this.maxBatchSize = 5;
        
        // Configuration des headers pour les requêtes
        this.headers = {
            'Authorization': `Bearer ${this.callboxToken}`,
            'Content-Type': 'application/json'
        };
        
        console.log('CallBox Sync Service initialisé');
    }

    // Démarrer le service de synchronisation
    start() {
        if (this.isRunning) {
            console.log('Service de synchronisation déjà en cours d\'exécution');
            return;
        }

        this.isRunning = true;
        console.log('Démarrage du service de synchronisation CallBox...');
        
        // Démarrer la synchronisation périodique
        this.syncInterval = setInterval(() => {
            this.syncPendingTransactions();
        }, this.syncIntervalMs);
        
        // Première synchronisation immédiate
        this.syncPendingTransactions();
    }

    // Arrêter le service de synchronisation
    stop() {
        if (!this.isRunning) {
            console.log('Service de synchronisation déjà arrêté');
            return;
        }

        this.isRunning = false;
        
        if (this.syncInterval) {
            clearInterval(this.syncInterval);
            this.syncInterval = null;
        }
        
        console.log('Service de synchronisation CallBox arrêté');
    }

    // Synchroniser les transactions en attente avec les CallBox actives
    async syncPendingTransactions() {
        try {
            // Vérifier les CallBox connectées
            const connectedCallBoxes = await this.getConnectedCallBoxes();
            
            if (connectedCallBoxes.length === 0) {
                console.log('Aucune CallBox connectée pour la synchronisation');
                return;
            }

            // Récupérer les transactions en attente depuis la base de données
            const pendingTransactions = await this.getPendingTransactionsFromDB();
            
            if (pendingTransactions.length === 0) {
                console.log('Aucune transaction en attente à synchroniser');
                return;
            }

            console.log(`Synchronisation de ${pendingTransactions.length} transactions avec ${connectedCallBoxes.length} CallBox(es)`);
            
            // Distribuer les transactions aux CallBox disponibles
            await this.distributeTransactions(pendingTransactions, connectedCallBoxes);
            
        } catch (error) {
            console.error('Erreur lors de la synchronisation:', error.message);
        }
    }

    // Récupérer la liste des CallBox connectées
    async getConnectedCallBoxes() {
        try {
            const response = await axios.get(`${this.baseUrl}/api/call-box/stats`, {
                headers: this.headers
            });
            
            if (response.data.success) {
                // Filtrer les CallBox actives
                return response.data.stats.instances.filter(instance => {
                    const lastHeartbeat = new Date(instance.lastHeartbeat);
                    const now = new Date();
                    const timeDiff = now - lastHeartbeat;
                    
                    // Considérer comme active si heartbeat dans les 30 dernières secondes
                    return instance.status === 'active' && timeDiff < 30000;
                });
            }
            
            return [];
        } catch (error) {
            console.error('Erreur lors de la récupération des CallBox:', error.message);
            return [];
        }
    }

    // Simuler la récupération des transactions en attente depuis la base de données
    // Dans un vrai environnement, ceci interrogerait votre base de données
    async getPendingTransactionsFromDB() {
        try {
            // Pour cette démo, nous utilisons des transactions simulées
            // Dans un vrai projet, ceci ferait appel à votre base de données
            const simulatedTransactions = this.generateSimulatedTransactions();
            
            return simulatedTransactions;
        } catch (error) {
            console.error('Erreur lors de la récupération des transactions:', error.message);
            return [];
        }
    }

    // Générer des transactions simulées pour les tests
    generateSimulatedTransactions() {
        const transactionTypes = ['recharge', 'voucher', 'deposit', 'withdraw'];
        const operators = ['MTN', 'Orange', 'Moov'];
        const transactions = [];
        
        // Générer entre 0 et 3 transactions simulées
        const count = Math.floor(Math.random() * 4);
        
        for (let i = 0; i < count; i++) {
            const type = transactionTypes[Math.floor(Math.random() * transactionTypes.length)];
            const operator = operators[Math.floor(Math.random() * operators.length)];
            
            transactions.push({
                type: type,
                phoneNumber: `+237${Math.floor(Math.random() * 900000000) + 600000000}`,
                amount: type === 'voucher' ? null : Math.floor(Math.random() * 10000) + 1000,
                payItemId: `${operator}_${type}_${Math.floor(Math.random() * 100)}`,
                customerInfo: {
                    name: `Customer ${Math.floor(Math.random() * 1000)}`,
                    operator: operator
                },
                priority: Math.random() > 0.8 ? 'high' : 'normal'
            });
        }
        
        return transactions;
    }

    // Distribuer les transactions aux CallBox disponibles
    async distributeTransactions(transactions, callboxes) {
        try {
            // Algorithme de distribution simple : round-robin
            let callboxIndex = 0;
            
            for (const transaction of transactions) {
                const targetCallBox = callboxes[callboxIndex % callboxes.length];
                
                try {
                    // Soumettre la transaction à la queue du CallBox
                    await this.submitTransactionToQueue(transaction);
                    
                    console.log(`Transaction ${transaction.type} assignée à CallBox ${targetCallBox.id}`);
                    
                    callboxIndex++;
                } catch (error) {
                    console.error(`Erreur lors de la soumission de transaction:`, error.message);
                }
            }
            
        } catch (error) {
            console.error('Erreur lors de la distribution des transactions:', error.message);
        }
    }

    // Soumettre une transaction à la queue
    async submitTransactionToQueue(transaction) {
        try {
            const response = await axios.post(`${this.baseUrl}/api/call-box/transactions/submit`, transaction, {
                headers: this.headers
            });
            
            return response.data;
        } catch (error) {
            throw new Error(`Échec de soumission: ${error.message}`);
        }
    }

    // Créer une transaction à partir des données reçues du système principal
    async createTransactionFromSystem(transactionData) {
        try {
            console.log('Création d\'une nouvelle transaction depuis le système:', transactionData);
            
            // Valider les données de transaction
            if (!transactionData.type || !transactionData.phoneNumber) {
                throw new Error('Type et numéro de téléphone requis');
            }
            
            // Soumettre immédiatement à la queue
            const result = await this.submitTransactionToQueue(transactionData);
            
            console.log('Transaction créée et ajoutée à la queue:', result.transactionId);
            
            return result;
        } catch (error) {
            console.error('Erreur lors de la création de transaction:', error.message);
            throw error;
        }
    }

    // Récupérer le statut de synchronisation
    async getSyncStatus() {
        try {
            const stats = await axios.get(`${this.baseUrl}/api/call-box/stats`, {
                headers: this.headers
            });
            
            return {
                isRunning: this.isRunning,
                syncInterval: this.syncIntervalMs,
                lastSync: new Date(),
                connectedCallBoxes: stats.data.success ? stats.data.stats.connectedInstances : 0,
                queueLength: stats.data.success ? stats.data.stats.queueLength : 0
            };
        } catch (error) {
            return {
                isRunning: this.isRunning,
                syncInterval: this.syncIntervalMs,
                error: error.message
            };
        }
    }

    // Mettre à jour la configuration de synchronisation
    updateConfig(config) {
        if (config.syncIntervalMs && config.syncIntervalMs > 1000) {
            this.syncIntervalMs = config.syncIntervalMs;
            
            // Redémarrer avec le nouveau délai si en cours d'exécution
            if (this.isRunning) {
                this.stop();
                this.start();
            }
        }
        
        if (config.maxBatchSize && config.maxBatchSize > 0) {
            this.maxBatchSize = config.maxBatchSize;
        }
        
        console.log('Configuration de synchronisation mise à jour:', {
            syncIntervalMs: this.syncIntervalMs,
            maxBatchSize: this.maxBatchSize
        });
    }

    // Forcer une synchronisation manuelle
    async forcSync() {
        console.log('Synchronisation manuelle forcée...');
        await this.syncPendingTransactions();
    }
}

module.exports = CallBoxSyncService;