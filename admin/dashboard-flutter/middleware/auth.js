// Middleware d'authentification pour protéger les routes admin

const requireAuth = (req, res, next) => {
  if (req.session.user) {
    next();
  } else {
    res.redirect('/login?redirect=' + encodeURIComponent(req.originalUrl));
  }
};

const redirectIfAuth = (req, res, next) => {
  if (req.session.user) {
    res.redirect('/dashboard');
  } else {
    next();
  }
};

module.exports = {
  requireAuth,
  redirectIfAuth
};