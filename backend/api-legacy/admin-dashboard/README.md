# Dashboard Admin MeRecharge

Un dashboard administrateur moderne et responsive pour gérer l'application MeRecharge, développé en fullstack avec Node.js/Express côté backend et HTML/CSS/JavaScript vanilla côté frontend.

## 🚀 Fonctionnalités

### Dashboard Principal
- **Statistiques en temps réel** : Transactions, revenus, taux de réussite
- **Graphiques interactifs** : Chart.js pour visualiser les données
- **Activité récente** : Monitoring des dernières transactions
- **Statut du serveur** : Vérification de l'état de connexion en temps réel

### Gestion des Transactions
- **Liste paginée** : Toutes les transactions avec filtres avancés
- **Filtrage** : Par type (recharge, forfait, dépôt, retrait), statut et date
- **Détails complets** : Informations détaillées de chaque transaction
- **Vérification** : Validation des transactions en attente

### Services Maviance
- **Liste des services** : Affichage de tous les services disponibles
- **Produits** : Consultation des produits topup et voucher par service
- **Statut** : Monitoring de l'état des services

### Synchronisation CallBox
- **Contrôle** : Démarrage/arrêt de la synchronisation
- **Monitoring** : Statut en temps réel et logs détaillés
- **Synchronisation forcée** : Option pour forcer une synchronisation immédiate

### Rapports et Analyses
- **Graphiques de revenus** : Évolution sur période personnalisée
- **Volume des transactions** : Analyse des tendances
- **Données exportables** : Possibilité d'exportation des rapports

### Paramètres Système
- **Configuration API** : Gestion des clés d'accès
- **Notifications** : Configuration des alertes
- **Sécurité** : Monitoring des accès et sessions

## 🛠 Technologies Utilisées

### Frontend
- **HTML5** : Structure sémantique moderne
- **CSS3** : Design responsive avec variables CSS et Flexbox/Grid
- **JavaScript ES6+** : Modules, async/await, fetch API
- **Chart.js** : Graphiques interactifs
- **Font Awesome** : Icônes modernes

### Backend (Extensions)
- **Node.js** : Serveur JavaScript
- **Express.js** : Framework web
- **Middleware de sécurité** : Authentification renforcée pour l'admin
- **API REST** : Endpoints dédiés à l'administration

## 📱 Design Responsive

Le dashboard s'adapte parfaitement à tous les écrans :
- **Desktop** : Interface complète avec sidebar fixe
- **Tablet** : Adaptation des grilles et espacements
- **Mobile** : Sidebar collapsible et interface optimisée

## 🔒 Sécurité

### Authentification
- **Connexion sécurisée** : Username/password avec limitation des tentatives
- **Sessions temporisées** : Expiration automatique après 8 heures
- **Logs de sécurité** : Traçabilité des connexions admin

### Protection
- **API Key** : Authentification des appels API
- **Middleware dédié** : Contrôle d'accès renforcé pour les routes admin
- **Prévention** : Protection contre les outils de développement en production

## 🚦 Installation et Utilisation

### 1. Démarrer le serveur backend
```bash
cd /Users/serge/Desktop/merecharge_backend
npm start
# ou
node server.js
```

### 2. Accéder au dashboard
- **URL** : http://localhost:3000/admin
- **Login** : http://localhost:3000/admin/login.html
- **Redirection automatique** : http://localhost:3000/admin-login

### 3. Identifiants par défaut
```
Username: admin
Password: merecharge2024
```

⚠️ **Important** : Changez ces identifiants en production !

## 📊 API Endpoints Admin

### Authentification
Toutes les routes admin nécessitent l'en-tête :
```
X-API-Key: votre_cle_api_secrete
```

### Endpoints disponibles

#### Statistiques
- `GET /api/admin/stats` - Statistiques globales du système

#### Transactions
- `GET /api/admin/transactions` - Liste paginée des transactions
  - Query params : `page`, `limit`, `type`, `status`, `date`
- `GET /api/admin/transaction/:id` - Détails d'une transaction

#### Rapports
- `GET /api/admin/reports` - Rapports personnalisés
  - Query params : `startDate`, `endDate`

#### Configuration
- `GET /api/admin/config` - Configuration système actuelle
- `POST /api/admin/config` - Mise à jour de la configuration

#### Logs
- `GET /api/admin/logs` - Logs système
  - Query params : `level`, `limit`

## 🎨 Personnalisation

### Variables CSS
Le design utilise des variables CSS personnalisables dans `assets/css/admin.css` :

```css
:root {
    --primary-color: #667eea;
    --secondary-color: #764ba2;
    --success-color: #28a745;
    --warning-color: #ffc107;
    --danger-color: #dc3545;
    /* ... autres variables */
}
```

### Configuration JavaScript
Variables configurables dans `assets/js/admin.js` :

```javascript
const API_BASE_URL = 'http://localhost:3000/api';
const API_KEY = 'votre_cle_api_secrete';
```

## 📁 Structure des Fichiers

```
admin-dashboard/
├── index.html              # Dashboard principal
├── login.html              # Page de connexion
├── README.md               # Cette documentation
├── assets/
│   ├── css/
│   │   └── admin.css       # Styles principaux
│   ├── js/
│   │   └── admin.js        # Logique JavaScript
│   └── img/                # Images (vide pour le moment)
├── pages/                  # Pages additionnelles (futures extensions)
└── components/             # Composants réutilisables (futures extensions)
```

## 🔧 Développement

### Ajout de nouvelles fonctionnalités

1. **Backend** : Ajouter de nouveaux endpoints dans `server.js`
2. **Frontend** : Étendre les modules JavaScript dans `admin.js`
3. **UI** : Ajouter les sections HTML dans `index.html`
4. **Styles** : Compléter le CSS dans `admin.css`

### Exemple d'ajout d'un module

```javascript
// Dans admin.js
const NouveauModule = {
    init() {
        this.bindEvents();
    },
    
    bindEvents() {
        // Événements spécifiques au module
    },
    
    async loadData() {
        // Chargement des données
    }
};

// Dans l'initialisation
document.addEventListener('DOMContentLoaded', () => {
    // ... autres modules
    NouveauModule.init();
});
```

## 🚀 Déploiement en Production

### Liste de contrôle sécurité

- [ ] Changer les identifiants admin par défaut
- [ ] Générer une nouvelle clé API sécurisée
- [ ] Configurer HTTPS
- [ ] Activer les logs de sécurité détaillés
- [ ] Mettre en place un système de backup
- [ ] Configurer un reverse proxy (Nginx/Apache)
- [ ] Limiter l'accès par IP si nécessaire

### Variables d'environnement

```bash
NODE_ENV=production
API_KEY=votre_cle_api_super_securisee
ADMIN_USERNAME=votre_admin_username
ADMIN_PASSWORD=votre_mot_de_passe_complexe
```

## 🐛 Dépannage

### Problèmes courants

1. **Dashboard non accessible**
   - Vérifier que le serveur est démarré sur le port 3000
   - Contrôler les logs du serveur pour les erreurs

2. **Erreur d'authentification**
   - Vérifier que la clé API correspond entre frontend et backend
   - Contrôler les identifiants de connexion

3. **Données non affichées**
   - Ouvrir la console du navigateur pour les erreurs JavaScript
   - Vérifier la connectivité avec l'API backend

4. **Interface non responsive**
   - Vider le cache du navigateur
   - Vérifier que le CSS se charge correctement

## 📞 Support

Pour toute question ou problème :

1. Consulter les logs du serveur dans la console
2. Utiliser les outils de développement du navigateur (F12)
3. Vérifier les endpoints API avec un client REST (Postman, etc.)

## 📝 Changelog

### Version 1.0.0 (Initial)
- Dashboard principal avec statistiques
- Gestion complète des transactions
- Interface de monitoring CallBox
- Système d'authentification admin
- Design responsive moderne
- API REST complète pour l'administration

## 🤝 Contribution

Ce dashboard a été développé comme une solution complète pour l'administration de MeRecharge. 

Pour contribuer :
1. Suivre les conventions de code existantes
2. Tester toutes les fonctionnalités sur différents navigateurs
3. Documenter les nouvelles fonctionnalités
4. Respecter les standards de sécurité

---

**MeRecharge Dashboard Admin** - Une solution complète de gestion développée avec passion ⚡