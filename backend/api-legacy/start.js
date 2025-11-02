const MavianceService = require('./maviance_service');

console.log('🚀 Démarrage du backend MeRecharge avec intégration Maviance\n');

// Afficher la configuration
console.log('📋 Configuration:');
console.log('- URL API:', process.env.S3P_URL || 'Non définie');
console.log('- Clé publique:', process.env.S3P_KEY ? process.env.S3P_KEY.substring(0, 8) + '...' : 'Non définie');
console.log('- Clé secrète:', process.env.S3P_SECRET ? 'Configurée' : 'Non définie');
console.log('');

// Démarrer le serveur
console.log('🔧 Démarrage du serveur Express...');
require('./server.js');