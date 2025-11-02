const bcrypt = require('bcryptjs');

// Base de données simulée des utilisateurs admin
// En production, ceci devrait être dans une vraie base de données
let adminUsers = [
  {
    id: 1,
    username: 'admin',
    email: 'admin@merecharge.com',
    password: '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
    role: 'super_admin',
    createdAt: new Date('2024-01-01'),
    lastLogin: null
  }
];

class AdminUserManager {
  // Créer un hash du mot de passe
  static async hashPassword(password) {
    return await bcrypt.hash(password, 10);
  }

  // Vérifier le mot de passe
  static async verifyPassword(password, hash) {
    return await bcrypt.compare(password, hash);
  }

  // Trouver un utilisateur par nom d'utilisateur
  static findByUsername(username) {
    return adminUsers.find(user => user.username === username);
  }

  // Trouver un utilisateur par email
  static findByEmail(email) {
    return adminUsers.find(user => user.email === email);
  }

  // Trouver un utilisateur par ID
  static findById(id) {
    return adminUsers.find(user => user.id === parseInt(id));
  }

  // Authentifier un utilisateur
  static async authenticate(username, password) {
    const user = this.findByUsername(username) || this.findByEmail(username);
    if (!user) {
      return null;
    }

    const isValid = await this.verifyPassword(password, user.password);
    if (!isValid) {
      return null;
    }

    // Mettre à jour la dernière connexion
    user.lastLogin = new Date();
    
    // Retourner les infos utilisateur sans le mot de passe
    const { password: _, ...userInfo } = user;
    return userInfo;
  }

  // Créer un nouvel utilisateur admin
  static async createUser(userData) {
    const hashedPassword = await this.hashPassword(userData.password);
    const newUser = {
      id: Math.max(...adminUsers.map(u => u.id), 0) + 1,
      username: userData.username,
      email: userData.email,
      password: hashedPassword,
      role: userData.role || 'admin',
      createdAt: new Date()
    };

    adminUsers.push(newUser);
    const { password: _, ...userInfo } = newUser;
    return userInfo;
  }

  // Obtenir tous les utilisateurs (sans mots de passe)
  static getAllUsers() {
    return adminUsers.map(user => {
      const { password: _, ...userInfo } = user;
      return userInfo;
    });
  }
}

module.exports = AdminUserManager;