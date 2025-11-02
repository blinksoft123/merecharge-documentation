const { Sequelize } = require('sequelize');
const path = require('path');

// Configuration de la base de données SQLite
const sequelize = new Sequelize({
  dialect: 'sqlite',
  storage: path.join(__dirname, '../database.sqlite'),
  logging: process.env.NODE_ENV === 'development' ? console.log : false,
  define: {
    timestamps: true,
    underscored: true,
    underscoredAll: true,
  },
});

// Test de la connexion
async function testConnection() {
  try {
    await sequelize.authenticate();
    console.log('✅ Connexion à la base de données réussie');
  } catch (error) {
    console.error('❌ Impossible de se connecter à la base de données:', error);
  }
}

module.exports = { sequelize, testConnection };