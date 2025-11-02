const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Transaction = sequelize.define('Transaction', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  transactionId: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
  },
  referenceId: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  serviceId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'services',
      key: 'id',
    },
  },
  userPhone: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  recipientPhone: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  amount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  fees: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    defaultValue: 0,
  },
  totalAmount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  status: {
    type: DataTypes.ENUM('pending', 'processing', 'success', 'failed', 'cancelled'),
    allowNull: false,
    defaultValue: 'pending',
  },
  mavianceReference: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  errorMessage: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  processedAt: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  completedAt: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  metadata: {
    type: DataTypes.JSON,
    allowNull: true,
  },
}, {
  tableName: 'transactions',
  indexes: [
    {
      fields: ['transaction_id'],
    },
    {
      fields: ['status'],
    },
    {
      fields: ['user_phone'],
    },
    {
      fields: ['service_id'],
    },
    {
      fields: ['created_at'],
    },
  ],
});

module.exports = Transaction;