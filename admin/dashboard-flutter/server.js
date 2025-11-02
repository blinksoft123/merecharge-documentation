const express = require('express');
const path = require('path');
const session = require('express-session');
const bodyParser = require('body-parser');
const expressLayouts = require('express-ejs-layouts');
require('dotenv').config();

// Configuration base de données
const { testConnection } = require('./config/database');
const { syncDatabase } = require('./models');

const app = express();
const PORT = process.env.PORT || 4000;

// Configuration EJS
app.set('view engine', 'ejs');
app.use(expressLayouts);
app.set('layout', 'layouts/main');
app.set('views', path.join(__dirname, 'views'));

// Middleware
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, 'public')));

// Configuration des sessions
app.use(session({
  secret: process.env.SESSION_SECRET || 'merecharge-admin-secret-key',
  resave: false,
  saveUninitialized: false,
  cookie: { secure: false, maxAge: 24 * 60 * 60 * 1000 } // 24 heures
}));

// Variables globales pour les vues
app.use((req, res, next) => {
  res.locals.user = req.session.user || null;
  res.locals.currentPath = req.path;
  next();
});

// Routes
const authRoutes = require('./routes/auth');
const dashboardRoutes = require('./routes/dashboard');
const usersRoutes = require('./routes/users');
const transactionsRoutes = require('./routes/transactions');
const configRoutes = require('./routes/config');

app.use('/', authRoutes);
app.use('/dashboard', dashboardRoutes);
app.use('/users', usersRoutes);
app.use('/transactions', transactionsRoutes);
app.use('/config', configRoutes);

// Route par défaut - redirection vers dashboard
app.get('/', (req, res) => {
  if (req.session.user) {
    res.redirect('/dashboard');
  } else {
    res.redirect('/login');
  }
});

// Gestion des erreurs 404
app.use((req, res) => {
  res.status(404).render('error', {
    title: 'Page non trouvée',
    message: 'La page demandée n\'existe pas.',
    layout: 'layouts/main'
  });
});

// Initialisation de la base de données et démarrage du serveur
async function startServer() {
  try {
    await testConnection();
    await syncDatabase();
    
    app.listen(PORT, () => {
      console.log(`🚀 Back-office MeRecharge démarré sur http://localhost:${PORT}`);
      console.log(`📋 Interface d'administration disponible`);
    });
  } catch (error) {
    console.error('❌ Erreur lors du démarrage:', error);
    process.exit(1);
  }
}

startServer();

module.exports = app;