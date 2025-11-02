const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const User = sequelize.define('User', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  phone: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
  },
  email: {
    type: DataTypes.STRING,
    allowNull: true,
    unique: true,
    validate: {
      isEmail: true,
    },
  },
  firstName: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  lastName: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true,
  },
  lastLoginAt: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  totalTransactions: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },
  totalSpent: {
    type: DataTypes.DECIMAL(15, 2),
    defaultValue: 0,
  },
  balance: {
    type: DataTypes.DECIMAL(15, 2),
    allowNull: false,
    defaultValue: 0.00,
    comment: 'Solde du portefeuille utilisateur en FCFA'
  },
  status: {
    type: DataTypes.ENUM('active', 'suspended', 'blocked'),
    allowNull: false,
    defaultValue: 'active',
  },
  name: {
    type: DataTypes.VIRTUAL,
    get() {
      return `${this.firstName || ''} ${this.lastName || ''}`.trim() || this.phone;
    },
  },
}, {
  tableName: 'users',
  indexes: [
    {
      fields: ['phone'],
    },
    {
      fields: ['email'],
    },
    {
      fields: ['is_active'],
    },
  ],
});

module.exports = User;