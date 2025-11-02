const express = require('express');
const router = express.Router();
const AdminUserManager = require('../data/admin_users');
const { redirectIfAuth } = require('../middleware/auth');

// Page de connexion
router.get('/login', redirectIfAuth, (req, res) => {
  const error = req.query.error;
  const redirect = req.query.redirect || '/dashboard';
  
  res.render('auth/login', {
    title: 'Connexion Admin',
    error: error,
    redirect: redirect
  });
});

// Traitement de la connexion
router.post('/login', redirectIfAuth, async (req, res) => {
  const { username, password, redirect } = req.body;
  
  try {
    const user = await AdminUserManager.authenticate(username, password);
    
    if (!user) {
      return res.redirect('/login?error=' + encodeURIComponent('Nom d\'utilisateur ou mot de passe incorrect'));
    }
    
    // Stocker l'utilisateur en session
    req.session.user = user;
    
    // Rediriger vers la page demandée ou dashboard
    const redirectUrl = redirect && redirect !== '/login' ? redirect : '/dashboard';
    res.redirect(redirectUrl);
    
  } catch (error) {
    console.error('Erreur lors de la connexion:', error);
    res.redirect('/login?error=' + encodeURIComponent('Une erreur est survenue'));
  }
});

// Déconnexion
router.get('/logout', (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      console.error('Erreur lors de la déconnexion:', err);
    }
    res.redirect('/login');
  });
});

// Route pour créer un compte admin (temporaire pour tests)
router.get('/create-admin', (req, res) => {
  res.render('auth/create-admin', {
    title: 'Créer un compte admin'
  });
});

router.post('/create-admin', async (req, res) => {
  const { username, email, password, confirmPassword } = req.body;
  
  if (password !== confirmPassword) {
    return res.render('auth/create-admin', {
      title: 'Créer un compte admin',
      error: 'Les mots de passe ne correspondent pas'
    });
  }
  
  try {
    // Vérifier si l'utilisateur existe déjà
    if (AdminUserManager.findByUsername(username)) {
      return res.render('auth/create-admin', {
        title: 'Créer un compte admin',
        error: 'Ce nom d\'utilisateur existe déjà'
      });
    }
    
    if (AdminUserManager.findByEmail(email)) {
      return res.render('auth/create-admin', {
        title: 'Créer un compte admin',
        error: 'Cet email est déjà utilisé'
      });
    }
    
    // Créer le nouvel utilisateur
    await AdminUserManager.createUser({
      username,
      email,
      password,
      role: 'admin'
    });
    
    res.redirect('/login?success=' + encodeURIComponent('Compte créé avec succès'));
    
  } catch (error) {
    console.error('Erreur lors de la création du compte:', error);
    res.render('auth/create-admin', {
      title: 'Créer un compte admin',
      error: 'Une erreur est survenue lors de la création du compte'
    });
  }
});

module.exports = router;