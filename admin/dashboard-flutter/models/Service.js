const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Service = sequelize.define('Service', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
  },
  displayName: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  icon: {
    type: DataTypes.STRING,
    allowNull: false,
    defaultValue: 'fas fa-cog',
  },
  color: {
    type: DataTypes.STRING,
    allowNull: false,
    defaultValue: 'primary',
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true,
  },
  serviceType: {
    type: DataTypes.ENUM('topup', 'data', 'bill', 'transfer', 'subscription'),
    allowNull: false,
  },
  provider: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  minAmount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
  },
  maxAmount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
  },
  fees: {
    type: DataTypes.DECIMAL(5, 4),
    allowNull: false,
    defaultValue: 0.02, // 2% par défaut
  },
  lastUsed: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  totalTransactions: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },
  totalRevenue: {
    type: DataTypes.DECIMAL(15, 2),
    defaultValue: 0,
  },
}, {
  tableName: 'services',
  indexes: [
    {
      fields: ['is_active'],
    },
    {
      fields: ['service_type'],
    },
    {
      fields: ['provider'],
    },
  ],
});

module.exports = Service;