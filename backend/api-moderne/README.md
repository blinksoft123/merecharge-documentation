# 🚀 Merecharge Backend Server

Backend API complet pour l'application Merecharge - Traitement des transactions et intégration des opérateurs camerounais.

## 🎯 **Fonctionnalités Principales**

### ✅ **Développé et Prêt**
- **Service USSD** complet (MTN, Orange, Camtel) 🔥 **CRITIQUE**
- **API Recharge** avec fallback automatique
- **Authentification API** sécurisée
- **Firebase Admin** intégration
- **Logging** structuré avec Winston
- **Error Handling** robuste
- **Rate Limiting** et sécurité

### 🔄 **En Cours de Développement**
- Services MTN/Orange (stubs créés)
- Webhooks handlers
- Autres routes (vouchers, deposits, etc.)

## 🚀 **Démarrage Rapide**

### 1. Installation
```bash
cd merecharge-backend
npm install
```

### 2. Configuration
```bash
# Copier le fichier d'environnement
cp .env.example .env

# Éditer .env avec vos vraies clés
nano .env
```

### 3. Variables Critiques à Configurer
```env
# Sécurité (OBLIGATOIRE)
API_KEY=votre-cle-api-super-secrete-ici
JWT_SECRET=votre-jwt-secret-256-bits

# Firebase Admin (OBLIGATOIRE)
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com

# APIs Opérateurs (OPTIONNEL pour commencer)
MTN_SUBSCRIPTION_KEY=your-mtn-key
ORANGE_CLIENT_ID=your-orange-client-id
```

### 4. Lancement
```bash
# Mode développement
npm run dev

# Mode production
npm start
```

### 5. Test
```bash
curl http://localhost:3000/api/ping
```

## 🔑 **Points Critiques Résolus**

### ✅ **Service USSD - Composant Critique**
Le service USSD est maintenant **implémenté et fonctionnel** :
- **MTN** : `*126*MONTANT*NUMERO#`
- **Orange** : `*144*MONTANT*NUMERO#` 
- **Camtel** : `*370*MONTANT*NUMERO#`

### ✅ **Backend Production Ready**
- **Remplace** le `localhost:3000` de l'app Flutter
- **Déployable** sur n'importe quel serveur Node.js
- **Scalable** et sécurisé

## 📱 **Intégration avec Flutter**

### Mettre à Jour l'App Flutter
Dans `lib/services/maviance_service.dart`, remplacez :
```dart
// AVANT (localhost)
static const String baseUrl = 'http://localhost:3000/api';

// APRÈS (votre serveur)
static const String baseUrl = 'https://your-domain.com/api';
```

### API Endpoints Disponibles
```
GET  /api/ping              - Test de connexion
POST /api/recharge          - Recharge de crédit
GET  /api/recharge/operators - Liste des opérateurs
POST /api/recharge/validate  - Validation des données
```

## 🛡️ **Sécurité**

### Authentication
Toutes les routes API nécessitent l'en-tête :
```
x-api-key: votre-cle-api-secrete
```

### Rate Limiting
- 100 requêtes par 15 minutes par IP
- Configurable dans `.env`

## 🔄 **Architecture**

```
merecharge-backend/
├── server.js              # Serveur principal
├── middleware/            # Auth, errors, logging
├── routes/               # Endpoints API
├── services/             # Logique métier
├── utils/                # Utilitaires (logger)
├── logs/                 # Fichiers de logs
└── package.json          # Dépendances
```

## 📈 **Monitoring & Logs**

### Logs Automatiques
- **Combined logs** : `logs/combined.log`
- **Error logs** : `logs/error.log`
- **Console output** en dev

### Health Check
```bash
curl http://localhost:3000/api/ping/health
```

## 🚀 **Déploiement Production**

### Option 1: VPS/Server Classique
```bash
# Sur votre serveur
git clone https://github.com/your-repo/merecharge-backend
cd merecharge-backend
npm install --production
cp .env.example .env
# Configurer .env
npm start
```

### Option 2: Docker (Recommandé)
```dockerfile
# Dockerfile inclus si besoin
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### Option 3: Services Cloud
- **Heroku** : Push direct
- **Railway** : Connect GitHub
- **DigitalOcean** : App Platform
- **AWS** : Elastic Beanstalk

## 🔧 **Maintenance**

### Logs Rotation
Les logs se rotation automatiquement (5MB max par fichier).

### Monitoring
Ajoutez des outils comme PM2 pour la production :
```bash
npm install -g pm2
pm2 start server.js --name merecharge-backend
pm2 startup
pm2 save
```

## 🆘 **Support & Dépannage**

### Problèmes Courants
1. **Port 3000 occupé** : Changez `PORT=3001` dans `.env`
2. **Firebase errors** : Vérifiez les clés dans `.env`
3. **CORS errors** : Ajoutez votre domaine à `ALLOWED_ORIGINS`

### Debug Mode
```bash
NODE_ENV=development LOG_LEVEL=debug npm run dev
```

## 📞 **Support**

Pour toute question sur l'intégration ou le déploiement, consultez les logs ou contactez l'équipe de développement.

---

**⚡ Ce backend résout le problème critique du localhost et rend l'application Merecharge prête pour la production ! ⚡**