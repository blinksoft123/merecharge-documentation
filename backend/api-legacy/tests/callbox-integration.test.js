const axios = require('axios');
const assert = require('assert');

// Configuration des tests
const BASE_URL = 'http://localhost:3000';
const API_KEY = 'votre_cle_api_secrete';
const CALLBOX_TOKEN = 'callbox-secure-token-2024';

// Headers pour les requêtes API
const apiHeaders = {
    'x-api-key': API_KEY,
    'Content-Type': 'application/json'
};

const callboxHeaders = {
    'Authorization': `Bearer ${CALLBOX_TOKEN}`,
    'Content-Type': 'application/json'
};

// Classe pour les tests d'intégration CallBox
class CallBoxIntegrationTests {
    constructor() {
        this.callboxId = `test_callbox_${Date.now()}`;
        this.testTransactions = [];
    }

    // Exécuter tous les tests
    async runAllTests() {
        console.log('🚀 Démarrage des tests d\'intégration CallBox...\n');

        try {
            // Tests de base
            await this.testServerConnection();
            await this.testCallBoxRegistration();
            await this.testHeartbeat();
            
            // Tests de gestion des transactions
            await this.testTransactionSubmission();
            await this.testTransactionRetrieval();
            await this.testTransactionStatusUpdate();
            
            // Tests de configuration
            await this.testConfigurationRetrieval();
            await this.testConfigurationUpdate();
            
            // Tests de synchronisation
            await this.testSyncService();
            
            // Tests de statistiques
            await this.testStatsRetrieval();
            
            // Tests de nettoyage
            await this.testQueueClear();
            
            console.log('\n✅ Tous les tests d\'intégration ont réussi!');
            
        } catch (error) {
            console.error('\n❌ Échec des tests d\'intégration:', error.message);
            throw error;
        }
    }

    // Test de connexion au serveur
    async testServerConnection() {
        console.log('📡 Test de connexion au serveur...');
        
        try {
            const response = await axios.get(`${BASE_URL}/`);
            assert(response.status === 200, 'Le serveur doit être accessible');
            assert(response.data.includes('MeRecharge'), 'Le serveur doit répondre avec le message MeRecharge');
            
            console.log('✅ Connexion au serveur réussie');
        } catch (error) {
            throw new Error(`Échec de connexion au serveur: ${error.message}`);
        }
    }

    // Test d'enregistrement du CallBox
    async testCallBoxRegistration() {
        console.log('📝 Test d\'enregistrement du CallBox...');
        
        try {
            const registrationData = {
                callboxId: this.callboxId,
                capabilities: {
                    maxConcurrentTransactions: 5,
                    supportedTypes: ['recharge', 'voucher', 'deposit', 'withdraw']
                },
                version: '1.0.0',
                location: 'Test Environment'
            };

            const response = await axios.post(
                `${BASE_URL}/api/call-box/register`,
                registrationData,
                { headers: callboxHeaders }
            );

            assert(response.status === 200, 'L\'enregistrement doit réussir');
            assert(response.data.success === true, 'La réponse doit indiquer un succès');
            assert(response.data.instance.id === this.callboxId, 'L\'ID CallBox doit correspondre');
            
            console.log('✅ Enregistrement du CallBox réussi');
        } catch (error) {
            throw new Error(`Échec d'enregistrement du CallBox: ${error.message}`);
        }
    }

    // Test du heartbeat
    async testHeartbeat() {
        console.log('💓 Test du heartbeat...');
        
        try {
            const heartbeatData = {
                callboxId: this.callboxId,
                status: 'active',
                queueSize: 0,
                metrics: {
                    uptime: 1000,
                    memoryUsage: 50
                }
            };

            const response = await axios.post(
                `${BASE_URL}/api/call-box/heartbeat`,
                heartbeatData,
                { headers: callboxHeaders }
            );

            assert(response.status === 200, 'Le heartbeat doit réussir');
            assert(response.data.success === true, 'La réponse doit indiquer un succès');
            assert(typeof response.data.pendingTransactions === 'number', 'Le nombre de transactions en attente doit être retourné');
            
            console.log('✅ Heartbeat réussi');
        } catch (error) {
            throw new Error(`Échec du heartbeat: ${error.message}`);
        }
    }

    // Test de soumission de transaction
    async testTransactionSubmission() {
        console.log('📤 Test de soumission de transaction...');
        
        try {
            const transactionData = {
                type: 'recharge',
                phoneNumber: '+237677123456',
                amount: 1000,
                payItemId: 'MTN_RECHARGE_1000',
                customerInfo: {
                    name: 'Test Customer',
                    operator: 'MTN'
                },
                priority: 'normal'
            };

            const response = await axios.post(
                `${BASE_URL}/api/call-box/transactions/submit`,
                transactionData,
                { headers: callboxHeaders }
            );

            assert(response.status === 200, 'La soumission doit réussir');
            assert(response.data.success === true, 'La réponse doit indiquer un succès');
            assert(response.data.transactionId, 'Un ID de transaction doit être retourné');
            
            // Stocker l'ID de transaction pour les tests suivants
            this.testTransactions.push(response.data.transactionId);
            
            console.log('✅ Soumission de transaction réussie');
        } catch (error) {
            throw new Error(`Échec de soumission de transaction: ${error.message}`);
        }
    }

    // Test de récupération des transactions en attente
    async testTransactionRetrieval() {
        console.log('📥 Test de récupération des transactions...');
        
        try {
            const response = await axios.get(
                `${BASE_URL}/api/call-box/transactions/pending?callboxId=${this.callboxId}&limit=10`,
                { headers: callboxHeaders }
            );

            assert(response.status === 200, 'La récupération doit réussir');
            assert(response.data.success === true, 'La réponse doit indiquer un succès');
            assert(Array.isArray(response.data.transactions), 'Les transactions doivent être un tableau');
            assert(response.data.transactions.length > 0, 'Au moins une transaction doit être retournée');
            
            console.log(`✅ Récupération de ${response.data.transactions.length} transaction(s) réussie`);
        } catch (error) {
            throw new Error(`Échec de récupération des transactions: ${error.message}`);
        }
    }

    // Test de mise à jour du statut de transaction
    async testTransactionStatusUpdate() {
        console.log('🔄 Test de mise à jour du statut de transaction...');
        
        if (this.testTransactions.length === 0) {
            throw new Error('Aucune transaction de test disponible');
        }

        try {
            const transactionId = this.testTransactions[0];
            const statusUpdateData = {
                status: 'processing',
                callboxId: this.callboxId,
                result: {
                    message: 'Transaction en cours de traitement'
                }
            };

            const response = await axios.put(
                `${BASE_URL}/api/call-box/transactions/${transactionId}/status`,
                statusUpdateData,
                { headers: callboxHeaders }
            );

            assert(response.status === 200, 'La mise à jour doit réussir');
            assert(response.data.success === true, 'La réponse doit indiquer un succès');
            assert(response.data.transaction.id === transactionId, 'L\'ID de transaction doit correspondre');
            
            console.log('✅ Mise à jour du statut réussie');
        } catch (error) {
            throw new Error(`Échec de mise à jour du statut: ${error.message}`);
        }
    }

    // Test de récupération de configuration
    async testConfigurationRetrieval() {
        console.log('⚙️ Test de récupération de configuration...');
        
        try {
            const response = await axios.get(
                `${BASE_URL}/api/call-box/config?callboxId=${this.callboxId}`,
                { headers: callboxHeaders }
            );

            assert(response.status === 200, 'La récupération doit réussir');
            assert(response.data.success === true, 'La réponse doit indiquer un succès');
            assert(response.data.config, 'La configuration doit être retournée');
            assert(typeof response.data.config.maxRetries === 'number', 'maxRetries doit être un nombre');
            
            console.log('✅ Récupération de configuration réussie');
        } catch (error) {
            throw new Error(`Échec de récupération de configuration: ${error.message}`);
        }
    }

    // Test de mise à jour de configuration
    async testConfigurationUpdate() {
        console.log('🔧 Test de mise à jour de configuration...');
        
        try {
            const configUpdateData = {
                maxRetries: 5,
                timeoutMs: 60000,
                batchSize: 10
            };

            const response = await axios.put(
                `${BASE_URL}/api/call-box/config`,
                configUpdateData,
                { headers: callboxHeaders }
            );

            assert(response.status === 200, 'La mise à jour doit réussir');
            assert(response.data.success === true, 'La réponse doit indiquer un succès');
            assert(response.data.config.maxRetries === 5, 'maxRetries doit être mis à jour');
            
            console.log('✅ Mise à jour de configuration réussie');
        } catch (error) {
            throw new Error(`Échec de mise à jour de configuration: ${error.message}`);
        }
    }

    // Test du service de synchronisation
    async testSyncService() {
        console.log('🔄 Test du service de synchronisation...');
        
        try {
            // Test du statut de synchronisation
            let response = await axios.get(
                `${BASE_URL}/api/sync/status`,
                { headers: apiHeaders }
            );

            assert(response.status === 200, 'La récupération du statut doit réussir');
            assert(response.data.success === true, 'La réponse doit indiquer un succès');
            
            // Test de synchronisation forcée
            response = await axios.post(
                `${BASE_URL}/api/sync/force`,
                {},
                { headers: apiHeaders }
            );

            assert(response.status === 200, 'La synchronisation forcée doit réussir');
            assert(response.data.success === true, 'La réponse doit indiquer un succès');
            
            console.log('✅ Service de synchronisation testé avec succès');
        } catch (error) {
            throw new Error(`Échec du test de synchronisation: ${error.message}`);
        }
    }

    // Test de récupération des statistiques
    async testStatsRetrieval() {
        console.log('📊 Test de récupération des statistiques...');
        
        try {
            const response = await axios.get(
                `${BASE_URL}/api/call-box/stats`,
                { headers: callboxHeaders }
            );

            assert(response.status === 200, 'La récupération doit réussir');
            assert(response.data.success === true, 'La réponse doit indiquer un succès');
            assert(response.data.stats, 'Les statistiques doivent être retournées');
            assert(typeof response.data.stats.connectedInstances === 'number', 'Le nombre d\'instances doit être un nombre');
            assert(response.data.stats.connectedInstances > 0, 'Au moins une instance doit être connectée');
            
            console.log('✅ Récupération des statistiques réussie');
        } catch (error) {
            throw new Error(`Échec de récupération des statistiques: ${error.message}`);
        }
    }

    // Test de nettoyage de la queue
    async testQueueClear() {
        console.log('🧹 Test de nettoyage de la queue...');
        
        try {
            const response = await axios.delete(
                `${BASE_URL}/api/call-box/transactions/clear`,
                { headers: callboxHeaders }
            );

            assert(response.status === 200, 'Le nettoyage doit réussir');
            assert(response.data.success === true, 'La réponse doit indiquer un succès');
            
            console.log('✅ Nettoyage de la queue réussi');
        } catch (error) {
            throw new Error(`Échec du nettoyage de la queue: ${error.message}`);
        }
    }

    // Test de création de transaction via le système principal
    async testSystemToCallBoxTransaction() {
        console.log('🔗 Test d\'envoi de transaction depuis le système principal...');
        
        try {
            const transactionData = {
                type: 'deposit',
                phoneNumber: '+237699876543',
                amount: 5000,
                payItemId: 'ORANGE_DEPOSIT_5000',
                customerInfo: {
                    name: 'System Customer',
                    operator: 'Orange'
                }
            };

            const response = await axios.post(
                `${BASE_URL}/api/transaction/to-callbox`,
                transactionData,
                { headers: apiHeaders }
            );

            assert(response.status === 200, 'L\'envoi doit réussir');
            assert(response.data.success === true, 'La réponse doit indiquer un succès');
            assert(response.data.transactionId, 'Un ID de transaction doit être retourné');
            
            console.log('✅ Envoi de transaction depuis le système principal réussi');
        } catch (error) {
            throw new Error(`Échec d'envoi de transaction: ${error.message}`);
        }
    }
}

// Fonction principale pour exécuter les tests
async function runTests() {
    const tests = new CallBoxIntegrationTests();
    
    try {
        await tests.runAllTests();
        
        // Test bonus: intégration système->CallBox
        await tests.testSystemToCallBoxTransaction();
        
        console.log('\n🎉 Tous les tests d\'intégration CallBox ont réussi!');
        process.exit(0);
        
    } catch (error) {
        console.error('\n💥 Échec des tests d\'intégration:', error.message);
        process.exit(1);
    }
}

// Exécuter les tests si ce fichier est appelé directement
if (require.main === module) {
    console.log('Assurez-vous que le serveur MeRecharge est en cours d\'exécution sur http://localhost:3000\n');
    
    // Délai pour permettre à l'utilisateur de démarrer le serveur si nécessaire
    setTimeout(() => {
        runTests();
    }, 1000);
}

module.exports = CallBoxIntegrationTests;