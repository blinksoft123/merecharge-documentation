// ========================================
//   MeRecharge Admin Dashboard - Custom JS
// ========================================

document.addEventListener('DOMContentLoaded', function() {
    // Animation pour les cartes statistiques
    const statCards = document.querySelectorAll('.stat-card');
    statCards.forEach((card, index) => {
        setTimeout(() => {
            card.style.opacity = '0';
            card.style.transform = 'translateY(20px)';
            card.style.transition = 'all 0.6s ease';
            
            setTimeout(() => {
                card.style.opacity = '1';
                card.style.transform = 'translateY(0)';
            }, 100);
        }, index * 100);
    });

    // Gestion du sidebar responsive
    const sidebar = document.querySelector('.sidebar');
    const toggleBtn = document.querySelector('.navbar-toggle');
    
    if (toggleBtn) {
        toggleBtn.addEventListener('click', () => {
            sidebar.classList.toggle('show');
        });
    }

    // Animation des badges
    const badges = document.querySelectorAll('.badge');
    badges.forEach(badge => {
        badge.addEventListener('mouseenter', () => {
            badge.style.transform = 'scale(1.05)';
        });
        badge.addEventListener('mouseleave', () => {
            badge.style.transform = 'scale(1)';
        });
    });

    // Auto-refresh des données (simulé)
    setInterval(() => {
        updateRealTimeData();
    }, 30000); // Toutes les 30 secondes
});

// Fonction pour mettre à jour les données en temps réel
function updateRealTimeData() {
    const statValues = document.querySelectorAll('.stat-value');
    statValues.forEach(element => {
        const currentValue = parseInt(element.textContent.replace(/[^0-9]/g, ''));
        if (currentValue) {
            const change = Math.floor(Math.random() * 10) - 5; // -5 à +5
            const newValue = Math.max(0, currentValue + change);
            
            // Animation de changement
            element.style.transition = 'all 0.3s ease';
            element.style.transform = 'scale(1.1)';
            element.style.color = 'var(--primary)';
            
            setTimeout(() => {
                element.textContent = newValue.toLocaleString();
                element.style.transform = 'scale(1)';
                element.style.color = '';
            }, 150);
        }
    });
}

// Fonction pour afficher les notifications toast
function showToast(message, type = 'info', duration = 4000) {
    const toast = document.createElement('div');
    toast.className = `toast show align-items-center text-bg-${type} border-0`;
    toast.style.position = 'fixed';
    toast.style.top = '20px';
    toast.style.right = '20px';
    toast.style.zIndex = '9999';
    toast.style.minWidth = '300px';
    
    const iconMap = {
        success: 'check-circle',
        danger: 'exclamation-circle',
        warning: 'exclamation-triangle',
        info: 'info-circle'
    };
    
    toast.innerHTML = `
        <div class="d-flex">
            <div class="toast-body">
                <i class="fas fa-${iconMap[type] || 'info-circle'} me-2"></i>
                ${message}
            </div>
            <button type="button" class="btn-close btn-close-white me-2 m-auto" onclick="this.parentElement.parentElement.remove()"></button>
        </div>
    `;
    
    document.body.appendChild(toast);
    
    // Animation d'entrée
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(100%)';
    setTimeout(() => {
        toast.style.transition = 'all 0.3s ease';
        toast.style.opacity = '1';
        toast.style.transform = 'translateX(0)';
    }, 100);
    
    // Auto-suppression
    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateX(100%)';
        setTimeout(() => {
            if (document.body.contains(toast)) {
                document.body.removeChild(toast);
            }
        }, 300);
    }, duration);
}

// Fonction pour confirmer les actions
function confirmAction(message, callback) {
    if (confirm(message)) {
        if (typeof callback === 'function') {
            callback();
        }
        return true;
    }
    return false;
}

// Fonction pour formater les nombres
function formatNumber(num) {
    if (num >= 1000000) {
        return (num / 1000000).toFixed(1) + 'M';
    } else if (num >= 1000) {
        return (num / 1000).toFixed(1) + 'k';
    }
    return num.toString();
}

// Fonction pour formater la devise
function formatCurrency(amount, currency = 'FCFA') {
    return new Intl.NumberFormat('fr-FR').format(amount) + ' ' + currency;
}

// Gestionnaire d'événements pour les boutons d'action
document.addEventListener('click', function(e) {
    // Gestion des boutons de suppression
    if (e.target.matches('[data-action="delete"]') || e.target.closest('[data-action="delete"]')) {
        e.preventDefault();
        const button = e.target.matches('[data-action="delete"]') ? e.target : e.target.closest('[data-action="delete"]');
        const message = button.getAttribute('data-confirm') || 'Êtes-vous sûr de vouloir supprimer cet élément ?';
        
        confirmAction(message, () => {
            // Ici, vous ajouteriez la logique de suppression
            showToast('Élément supprimé avec succès', 'success');
        });
    }
    
    // Gestion des boutons de copie
    if (e.target.matches('[data-action="copy"]') || e.target.closest('[data-action="copy"]')) {
        e.preventDefault();
        const button = e.target.matches('[data-action="copy"]') ? e.target : e.target.closest('[data-action="copy"]');
        const textToCopy = button.getAttribute('data-text') || button.textContent;
        
        navigator.clipboard.writeText(textToCopy).then(() => {
            showToast('Texte copié dans le presse-papiers', 'success');
            
            // Animation du bouton
            button.style.transform = 'scale(0.95)';
            setTimeout(() => {
                button.style.transform = 'scale(1)';
            }, 150);
        });
    }
});

// Fonction pour recharger les données
function refreshData() {
    showToast('Actualisation des données...', 'info');
    
    // Simulation du rechargement
    setTimeout(() => {
        showToast('Données actualisées avec succès', 'success');
        updateRealTimeData();
    }, 1500);
}

// Gestion des formulaires avec validation
document.addEventListener('submit', function(e) {
    const form = e.target;
    if (form.classList.contains('needs-validation')) {
        e.preventDefault();
        e.stopPropagation();
        
        if (form.checkValidity()) {
            // Formulaire valide, traitement...
            showToast('Formulaire soumis avec succès', 'success');
        } else {
            showToast('Veuillez corriger les erreurs dans le formulaire', 'danger');
        }
        
        form.classList.add('was-validated');
    }
});

// Fonction d'initialisation pour les tooltips et popovers Bootstrap
function initBootstrapComponents() {
    // Tooltips
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });
    
    // Popovers
    const popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
    popoverTriggerList.map(function (popoverTriggerEl) {
        return new bootstrap.Popover(popoverTriggerEl);
    });
}

// Initialiser les composants Bootstrap après le chargement du DOM
document.addEventListener('DOMContentLoaded', initBootstrapComponents);