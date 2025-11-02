// ===============================
// Les services Firebase sont maintenant initialisés dans firebase-config.js
// adminAuth et firebaseData sont disponibles globalement

// ===============================
// Variables Globales
// ===============================
let currentSection = 'dashboard';
let currentPage = 1;
let totalPages = 1;
let charts = {};
let userData = [];
let transactionData = [];
let isLoading = false;

// ===============================
// Initialisation de l'application
// ===============================
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
    setupEventListeners();
    setupKeyboardShortcuts();
    setupTooltips();
    setupThemeToggle();
    loadDashboardData();
    initializeCharts();
});

function initializeApp() {
    // Simuler l'initialisation de Firebase
    console.log('🚀 MeRecharge Admin Dashboard - Initialisation...');
    updateFirebaseStatus(true);
    
    // Configuration initiale
    setupNavigation();
    setupResponsiveMenu();
    
    console.log('✅ Application initialisée avec succès');
}

function updateFirebaseStatus(connected) {
    const statusIcon = document.getElementById('firebaseStatus');
    const statusText = document.getElementById('firebaseStatusText');
    
    if (!statusIcon || !statusText) {
        console.warn('Firebase status elements not found');
        return;
    }
    
    if (connected) {
        statusIcon.className = 'fas fa-database status-icon';
        statusText.textContent = 'Firebase Connected';
    } else {
        statusIcon.className = 'fas fa-exclamation-circle';
        statusIcon.style.color = 'var(--danger-color)';
        statusText.textContent = 'Firebase Disconnected';
    }
}

// ===============================
// Configuration des Event Listeners
// ===============================
function setupEventListeners() {
    console.log('🔧 Configuration des event listeners...');
    
    // Navigation
    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', handleNavigation);
        console.log('📋 Event listener ajouté pour:', link.dataset.section);
    });
    
    // Toggle sidebar mobile
    const sidebarToggle = document.querySelector('.sidebar-toggle');
    if (sidebarToggle) {
        sidebarToggle.addEventListener('click', toggleSidebar);
    }
    
    // Recherche
    const searchInput = document.getElementById('search-input');
    if (searchInput) {
        searchInput.addEventListener('input', debounce(handleSearch, 300));
    }
    
    // Modals
    document.querySelectorAll('.modal-close').forEach(closeBtn => {
        closeBtn.addEventListener('click', closeModal);
    });
    
    // Fermer modal en cliquant sur l'overlay
    document.querySelectorAll('.modal').forEach(modal => {
        modal.addEventListener('click', function(e) {
            if (e.target === this) {
                closeModal();
            }
        });
    });
    
    // Actions rapides
    setupQuickActions();
    
    // Filtres et recherches
    setupFilters();
    
    // Boutons d'actions
    setupActionButtons();
}

function setupFilters() {
    // Recherche utilisateurs
    const userSearch = document.getElementById('userSearch');
    if (userSearch) {
        userSearch.addEventListener('input', debounce(function() {
            loadUsersData(this.value);
        }, 300));
    }
    
    // Filtres transactions
    const transactionFilters = ['transactionTypeFilter', 'transactionStatusFilter', 'transactionDateFilter'];
    transactionFilters.forEach(filterId => {
        const element = document.getElementById(filterId);
        if (element) {
            element.addEventListener('change', function() {
                const filters = {
                    type: document.getElementById('transactionTypeFilter')?.value || '',
                    status: document.getElementById('transactionStatusFilter')?.value || '',
                    dateFrom: document.getElementById('transactionDateFilter')?.value || ''
                };
                loadTransactionsData(filters);
            });
        }
    });
    
    // Filtres recharges
    const rechargeFilters = ['rechargeOperatorFilter', 'rechargeStatusFilter', 'rechargeDateFilter'];
    rechargeFilters.forEach(filterId => {
        const element = document.getElementById(filterId);
        if (element) {
            element.addEventListener('change', function() {
                const filters = {
                    operator: document.getElementById('rechargeOperatorFilter')?.value || '',
                    status: document.getElementById('rechargeStatusFilter')?.value || '',
                    dateFrom: document.getElementById('rechargeDateFilter')?.value || ''
                };
                loadRechargesData(filters);
            });
        }
    });
    
    // Filtre produits
    const productCategoryFilter = document.getElementById('productCategoryFilter');
    if (productCategoryFilter) {
        productCategoryFilter.addEventListener('change', function() {
            loadProductsData(this.value);
        });
    }
}

function setupActionButtons() {
    // Bouton ajouter produit
    const addProductBtn = document.getElementById('addProductBtn');
    if (addProductBtn) {
        addProductBtn.addEventListener('click', showAddProductModal);
    }
    
    // Boutons d'export
    const exportBtns = {
        'exportUsersBtn': () => exportData('users'),
        'exportRechargesBtn': () => exportData('recharges')
    };
    
    Object.keys(exportBtns).forEach(btnId => {
        const btn = document.getElementById(btnId);
        if (btn) {
            btn.addEventListener('click', exportBtns[btnId]);
        }
    });
    
    // Boutons de filtre
    const filterBtns = {
        'filterTransactionsBtn': () => {
            const filters = {
                type: document.getElementById('transactionTypeFilter')?.value || '',
                status: document.getElementById('transactionStatusFilter')?.value || '',
                dateFrom: document.getElementById('transactionDateFilter')?.value || ''
            };
            loadTransactionsData(filters);
        },
        'filterRechargesBtn': () => {
            const filters = {
                operator: document.getElementById('rechargeOperatorFilter')?.value || '',
                status: document.getElementById('rechargeStatusFilter')?.value || '',
                dateFrom: document.getElementById('rechargeDateFilter')?.value || ''
            };
            loadRechargesData(filters);
        },
        'filterOrdersBtn': () => {
            const filters = {
                status: document.getElementById('orderStatusFilter')?.value || '',
                dateFrom: document.getElementById('orderDateFilter')?.value || ''
            };
            loadOrdersData(filters);
        }
    };
    
    Object.keys(filterBtns).forEach(btnId => {
        const btn = document.getElementById(btnId);
        if (btn) {
            btn.addEventListener('click', filterBtns[btnId]);
        }
    });
}

function setupQuickActions() {
    // Boutons d'actions
    document.querySelectorAll('[data-action]').forEach(button => {
        button.addEventListener('click', function() {
            const action = this.dataset.action;
            handleQuickAction(action);
        });
    });
}

// ===============================
// Navigation
// ===============================
function handleNavigation(e) {
    e.preventDefault();
    const sectionId = this.dataset.section;
    
    console.log('📍 Navigation vers:', sectionId);
    
    if (sectionId) {
        switchSection(sectionId);
        updatePageTitle(this.textContent.trim());
        
        // Mettre à jour l'état actif de la navigation
        document.querySelectorAll('.nav-link').forEach(link => {
            link.classList.remove('active');
        });
        this.classList.add('active');
        
        // Fermer le sidebar mobile après navigation
        if (window.innerWidth <= 768) {
            document.querySelector('.sidebar').classList.remove('open');
        }
        
        currentSection = sectionId;
    }
}

function switchSection(sectionId) {
    console.log('🔄 Changement de section vers:', sectionId);
    
    // Cacher toutes les sections
    document.querySelectorAll('.content-section').forEach(section => {
        section.classList.remove('active');
        console.log('🚫 Section cachée:', section.id);
    });
    
    // Afficher la section demandée - utiliser le bon ID
    let targetSectionId = sectionId;
    
    // Mapper les IDs de navigation aux IDs des sections
    const sectionMapping = {
        'dashboard': 'dashboard-section',
        'users': 'users-section', 
        'transactions': 'transactions-section',
        'recharges': 'recharges-section',
        'bundles': 'bundles-section',
        'orders': 'orders-section',
        'products': 'products-section',
        'notifications': 'notifications-section',
        'reports': 'reports-section',
        'settings': 'settings-section'
    };
    
    targetSectionId = sectionMapping[sectionId] || sectionId + '-section';
    
    const targetSection = document.getElementById(targetSectionId);
    if (targetSection) {
        targetSection.classList.add('active');
        console.log('✅ Section activée:', targetSectionId);
        
        // Charger les données spécifiques à la section
        loadSectionData(sectionId);
    } else {
        console.error('❌ Section introuvable:', targetSectionId);
    }
}

function updatePageTitle(title) {
    const pageTitle = document.querySelector('.page-title');
    if (pageTitle) {
        pageTitle.textContent = title;
    }
    document.title = `${title} - MeRecharge Admin`;
}

function setupNavigation() {
    // Activer la première navigation par défaut
    const firstNavLink = document.querySelector('.nav-link');
    if (firstNavLink) {
        firstNavLink.classList.add('active');
    }
}

// ===============================
// Menu Responsif
// ===============================
function setupResponsiveMenu() {
    // Créer le bouton toggle s'il n'existe pas
    const headerLeft = document.querySelector('.header-left');
    if (headerLeft && !document.querySelector('.sidebar-toggle')) {
        const toggleBtn = document.createElement('button');
        toggleBtn.className = 'sidebar-toggle';
        toggleBtn.innerHTML = '<i class="fas fa-bars"></i>';
        toggleBtn.addEventListener('click', toggleSidebar);
        headerLeft.insertBefore(toggleBtn, headerLeft.firstChild);
    }
}

function setupKeyboardShortcuts() {
    document.addEventListener('keydown', function(e) {
        // Échap pour fermer les modals
        if (e.key === 'Escape') {
            const openModal = document.querySelector('.modal.show');
            if (openModal) {
                closeModal();
                e.preventDefault();
            }
        }
        
        // Ctrl+S pour sauvegarder (dans les formulaires)
        if (e.ctrlKey && e.key === 's') {
            const activeModal = document.querySelector('.modal.show');
            if (activeModal) {
                const submitBtn = activeModal.querySelector('button[type="submit"], .btn-primary');
                if (submitBtn && !submitBtn.disabled) {
                    submitBtn.click();
                    e.preventDefault();
                    showToast('Raccourci Ctrl+S détecté - Sauvegarde...', 'info');
                }
            }
        }
        
        // Ctrl+F pour la recherche
        if (e.ctrlKey && e.key === 'f') {
            const searchInput = document.getElementById('search-input') || document.getElementById('userSearch');
            if (searchInput) {
                searchInput.focus();
                searchInput.select();
                e.preventDefault();
                showToast('Mode recherche activé', 'info');
            }
        }
        
        // Alt+N pour nouveau (selon la section active)
        if (e.altKey && e.key === 'n') {
            const currentSection = document.querySelector('.content-section.active');
            if (currentSection) {
                const addBtn = currentSection.querySelector('#addProductBtn, #addBundleBtn, .btn-primary');
                if (addBtn && addBtn.textContent.toLowerCase().includes('nouveau')) {
                    addBtn.click();
                    e.preventDefault();
                    showToast('Nouveau élément - Raccourci Alt+N', 'info');
                }
            }
        }
        
        // Flèches pour navigation rapide dans les tableaux
        if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
            const focusedRow = document.activeElement.closest('tr');
            if (focusedRow && focusedRow.parentElement.tagName === 'TBODY') {
                const rows = Array.from(focusedRow.parentElement.children);
                const currentIndex = rows.indexOf(focusedRow);
                let nextIndex;
                
                if (e.key === 'ArrowDown') {
                    nextIndex = Math.min(currentIndex + 1, rows.length - 1);
                } else {
                    nextIndex = Math.max(currentIndex - 1, 0);
                }
                
                if (nextIndex !== currentIndex) {
                    const nextRow = rows[nextIndex];
                    const firstButton = nextRow.querySelector('button');
                    if (firstButton) {
                        firstButton.focus();
                        e.preventDefault();
                    }
                }
            }
        }
        
        // Entrée pour éditer l'élément sélectionné
        if (e.key === 'Enter' && !e.shiftKey && !e.ctrlKey) {
            const focusedButton = document.activeElement;
            if (focusedButton && focusedButton.tagName === 'BUTTON') {
                const row = focusedButton.closest('tr');
                if (row) {
                    const editBtn = row.querySelector('.btn-warning, [title*="Modifier"]');
                    if (editBtn && editBtn !== focusedButton) {
                        editBtn.click();
                        e.preventDefault();
                    }
                }
            }
        }
    });
    
    console.log('⌨️ Raccourcis clavier activés:');
    console.log('  - Échap: Fermer les modals');
    console.log('  - Ctrl+S: Sauvegarder');
    console.log('  - Ctrl+F: Recherche');
    console.log('  - Alt+N: Nouveau');
    console.log('  - Flèches: Navigation tableaux');
    console.log('  - Entrée: Éditer l\'item');
}

function setupTooltips() {
    // Créer les styles CSS pour les tooltips
    const tooltipStyles = document.createElement('style');
    tooltipStyles.textContent = `
        .help-tooltip {
            position: relative;
            display: inline-block;
            margin-left: 0.5rem;
            cursor: help;
        }
        
        .help-tooltip i {
            color: #6b7280;
            font-size: 0.9rem;
            transition: color 0.2s;
        }
        
        .help-tooltip:hover i {
            color: var(--primary-color);
        }
        
        .help-tooltip::before {
            content: attr(data-tooltip);
            position: absolute;
            bottom: 125%;
            left: 50%;
            transform: translateX(-50%);
            background-color: #1f2937;
            color: white;
            padding: 0.75rem 1rem;
            border-radius: 0.5rem;
            font-size: 0.8rem;
            white-space: nowrap;
            max-width: 300px;
            white-space: normal;
            text-align: center;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
            opacity: 0;
            visibility: hidden;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            z-index: 1000;
        }
        
        .help-tooltip::after {
            content: '';
            position: absolute;
            bottom: 115%;
            left: 50%;
            transform: translateX(-50%);
            border: 5px solid transparent;
            border-top-color: #1f2937;
            opacity: 0;
            visibility: hidden;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }
        
        .help-tooltip:hover::before,
        .help-tooltip:hover::after {
            opacity: 1;
            visibility: visible;
        }
        
        /* Tooltips responsifs sur mobile */
        @media (max-width: 768px) {
            .help-tooltip::before {
                position: fixed;
                bottom: 20px;
                left: 20px;
                right: 20px;
                transform: none;
                max-width: none;
                border-radius: 0.75rem;
                font-size: 0.9rem;
                padding: 1rem;
            }
            
            .help-tooltip::after {
                display: none;
            }
        }
        
        /* Animation pour les tooltips d'action */
        .action-tooltip {
            position: relative;
        }
        
        .action-tooltip::before {
            content: attr(data-tooltip);
            position: absolute;
            bottom: 120%;
            left: 50%;
            transform: translateX(-50%);
            background-color: #374151;
            color: white;
            padding: 0.5rem 0.75rem;
            border-radius: 0.375rem;
            font-size: 0.75rem;
            white-space: nowrap;
            opacity: 0;
            visibility: hidden;
            transition: all 0.2s;
            z-index: 1000;
        }
        
        .action-tooltip:hover::before {
            opacity: 1;
            visibility: visible;
        }
    `;
    document.head.appendChild(tooltipStyles);
    
    // Ajouter des tooltips aux boutons d'actions existants
    addActionTooltips();
    
    console.log('❓ Tooltips d\'aide activés');
}

function addActionTooltips() {
    // Ajouter des tooltips aux boutons dans les tableaux
    document.addEventListener('click', function() {
        // Attendre que les tableaux soient rendus
        setTimeout(() => {
            // Boutons utilisateurs
            document.querySelectorAll('button[onclick*="viewUser"]').forEach(btn => {
                if (!btn.hasAttribute('data-tooltip')) {
                    btn.classList.add('action-tooltip');
                    btn.setAttribute('data-tooltip', 'Voir les détails de l\'utilisateur');
                }
            });
            
            document.querySelectorAll('button[onclick*="editUser"]').forEach(btn => {
                if (!btn.hasAttribute('data-tooltip')) {
                    btn.classList.add('action-tooltip');
                    btn.setAttribute('data-tooltip', 'Modifier l\'utilisateur (Ctrl+S pour sauvegarder)');
                }
            });
            
            document.querySelectorAll('button[onclick*="toggleUserStatus"]').forEach(btn => {
                if (!btn.hasAttribute('data-tooltip')) {
                    btn.classList.add('action-tooltip');
                    const isActive = btn.innerHTML.includes('pause');
                    btn.setAttribute('data-tooltip', isActive ? 'Désactiver l\'utilisateur' : 'Activer l\'utilisateur');
                }
            });
            
            document.querySelectorAll('button[onclick*="deleteUser"]').forEach(btn => {
                if (!btn.hasAttribute('data-tooltip')) {
                    btn.classList.add('action-tooltip');
                    btn.setAttribute('data-tooltip', 'Supprimer définitivement (irréversible)');
                }
            });
            
            // Boutons produits
            document.querySelectorAll('button[onclick*="editProduct"]').forEach(btn => {
                if (!btn.hasAttribute('data-tooltip')) {
                    btn.classList.add('action-tooltip');
                    btn.setAttribute('data-tooltip', 'Modifier le produit');
                }
            });
            
        }, 100);
    });
}

function setupThemeToggle() {
    const themeToggle = document.getElementById('themeToggle');
    const themeIcon = document.getElementById('themeIcon');
    const body = document.body;
    
    // Récupérer le thème sauvegardé ou utiliser le clair par défaut
    const currentTheme = localStorage.getItem('theme') || 'light';
    
    // Appliquer le thème initial
    if (currentTheme === 'dark') {
        body.classList.add('dark-theme');
        themeIcon.className = 'fas fa-sun';
    } else {
        body.classList.remove('dark-theme');
        themeIcon.className = 'fas fa-moon';
    }
    
    // Créer les variables CSS pour le thème sombre
    const darkThemeStyles = document.createElement('style');
    darkThemeStyles.textContent = `
        .dark-theme {
            --bg-primary: #1a1a1a;
            --bg-secondary: #2d2d2d;
            --bg-tertiary: #3d3d3d;
            --text-primary: #ffffff;
            --text-secondary: #cccccc;
            --text-tertiary: #999999;
            --border-color: #444444;
            --shadow-color: rgba(0, 0, 0, 0.3);
        }
        
        .dark-theme .sidebar {
            background: var(--bg-secondary);
            border-right-color: var(--border-color);
        }
        
        .dark-theme .main-header {
            background: var(--bg-secondary);
            border-bottom-color: var(--border-color);
            color: var(--text-primary);
        }
        
        .dark-theme .content-area {
            background: var(--bg-primary);
            color: var(--text-primary);
        }
        
        .dark-theme .stat-card {
            background: var(--bg-secondary);
            border-color: var(--border-color);
            color: var(--text-primary);
        }
        
        .dark-theme .chart-container {
            background: var(--bg-secondary);
            border-color: var(--border-color);
        }
        
        .dark-theme .data-table {
            background: var(--bg-secondary);
            color: var(--text-primary);
        }
        
        .dark-theme .data-table th {
            background: var(--bg-tertiary);
            border-color: var(--border-color);
        }
        
        .dark-theme .data-table td {
            border-color: var(--border-color);
        }
        
        .dark-theme .data-table tbody tr:hover {
            background: var(--bg-tertiary);
        }
        
        .dark-theme .modal-content {
            background: var(--bg-secondary);
            color: var(--text-primary);
        }
        
        .dark-theme .form-control {
            background: var(--bg-tertiary);
            border-color: var(--border-color);
            color: var(--text-primary);
        }
        
        .dark-theme .form-control:focus {
            border-color: var(--primary-color);
            box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
        }
        
        .dark-theme .btn {
            border-color: var(--border-color);
        }
        
        .dark-theme .btn-secondary {
            background: var(--bg-tertiary);
            color: var(--text-primary);
        }
        
        .dark-theme .sidebar-nav a {
            color: var(--text-secondary);
        }
        
        .dark-theme .sidebar-nav a:hover,
        .dark-theme .sidebar-nav a.active {
            background: rgba(79, 70, 229, 0.1);
            color: var(--primary-color);
        }
        
        .dark-theme .nav-link {
            color: var(--text-secondary);
        }
        
        .dark-theme .nav-link.active {
            color: var(--primary-color);
        }
        
        .dark-theme .product-card {
            background: var(--bg-secondary);
            border-color: var(--border-color);
        }
        
        .dark-theme .empty-state {
            color: var(--text-secondary);
        }
        
        .dark-theme .coming-soon {
            background: var(--bg-secondary);
            color: var(--text-secondary);
        }
        
        .dark-theme h1, .dark-theme h2, .dark-theme h3, .dark-theme h4 {
            color: var(--text-primary);
        }
        
        /* Animation de transition */
        * {
            transition: background-color 0.3s ease, color 0.3s ease, border-color 0.3s ease;
        }
    `;
    document.head.appendChild(darkThemeStyles);
    
    // Gestionnaire de clic pour le toggle
    if (themeToggle) {
        themeToggle.addEventListener('click', function() {
            const isDark = body.classList.contains('dark-theme');
            
            if (isDark) {
                // Passer au thème clair
                body.classList.remove('dark-theme');
                themeIcon.className = 'fas fa-moon';
                localStorage.setItem('theme', 'light');
                showSuccessToast('☀️ Thème clair activé', { duration: 2000 });
            } else {
                // Passer au thème sombre
                body.classList.add('dark-theme');
                themeIcon.className = 'fas fa-sun';
                localStorage.setItem('theme', 'dark');
                showSuccessToast('🌙 Thème sombre activé', { duration: 2000 });
            }
        });
    }
    
    console.log(`🎨 Thème ${currentTheme} appliqué`);
}

function toggleSidebar() {
    const sidebar = document.querySelector('.sidebar');
    sidebar.classList.toggle('open');
}

// ===============================
// Gestion des Données
// ===============================
async function loadDashboardData() {
    showLoading();
    
    try {
        // Charger les statistiques réelles depuis Firebase
        const stats = await firebaseData.getDashboardStats();
        updateStatsCards(stats);
        
        // Charger l'activité récente
        await loadRecentActivity();
        
        // Charger les données des graphiques
        await loadChartData();
        
        hideLoading();
    } catch (error) {
        console.error('❌ Erreur lors du chargement du dashboard:', error);
        showToast('Erreur lors du chargement des données', 'error');
        hideLoading();
    }
}

function loadSectionData(sectionId) {
    console.log('📊 Chargement des données pour la section:', sectionId);
    
    switch (sectionId) {
        case 'dashboard':
            // Déjà chargé à l'initialisation
            console.log('📊 Dashboard déjà chargé');
            break;
        case 'users':
            loadUsersData();
            break;
        case 'transactions':
            loadTransactionsData();
            break;
        case 'recharges':
            loadRechargesData();
            break;
        case 'bundles':
            console.log('📶 Section Forfaits (en développement)');
            break;
        case 'orders':
            loadOrdersData();
            break;
        case 'products':
            loadProductsData();
            break;
        case 'notifications':
            loadNotificationsData();
            break;
        case 'reports':
            loadReportsData();
            break;
        case 'settings':
            loadSettingsData();
            break;
        default:
            console.warn('⚠️ Section inconnue:', sectionId);
    }
}

function updateStatsCards(stats) {
    // Utilisateurs
    updateStatCard('users-count', stats.users.total);
    updateTrend('users-trend', stats.users.trend, stats.users.positive);
    
    // Revenus
    updateStatCard('revenue-amount', formatCurrency(stats.revenue.total));
    updateTrend('revenue-trend', stats.revenue.trend, stats.revenue.positive);
    
    // Transactions
    updateStatCard('transactions-count', stats.transactions.total);
    updateTrend('transactions-trend', stats.transactions.trend, stats.transactions.positive);
    
    // Commandes
    updateStatCard('orders-count', stats.orders.total);
    updateTrend('orders-trend', stats.orders.trend, stats.orders.positive);
}

function updateStatCard(elementId, value) {
    const element = document.getElementById(elementId);
    if (element) {
        element.textContent = typeof value === 'number' ? formatNumber(value) : value;
    }
}

function updateTrend(elementId, trend, isPositive) {
    const element = document.getElementById(elementId);
    if (element) {
        element.textContent = trend;
        element.className = `trend ${isPositive ? 'positive' : 'negative'}`;
        const icon = element.querySelector('i') || document.createElement('i');
        icon.className = `fas fa-arrow-${isPositive ? 'up' : 'down'}`;
        if (!element.querySelector('i')) {
            element.prepend(icon);
        }
    }
}

// ===============================
// Chargement des données par section
// ===============================
async function loadUsersData(searchQuery = null) {
    console.log('👥 Début du chargement des utilisateurs...');
    showLoading();
    
    try {
        // Vérifier si Firebase est configuré
        if (!window.firebase) {
            console.error('❌ Firebase SDK non chargé');
            throw new Error('Firebase non disponible');
        }
        
        // Vérifier si firebaseData est disponible
        if (typeof window.firebaseData === 'undefined' || !window.firebaseData) {
            console.error('❌ Service firebaseData non disponible');
            throw new Error('Service Firebase non initialisé');
        }
        
        console.log('✅ Firebase détecté, chargement des utilisateurs réels...');
        
        // Charger les utilisateurs réels depuis Firebase
        const result = await window.firebaseData.getUsers(50, null, searchQuery);
        userData = result.users || [];
        
        console.log(`📊 ${userData.length} utilisateurs chargés depuis Firebase`);
        
        renderUsersTable();
        hideLoading();
        
    } catch (error) {
        console.error('❌ Erreur lors du chargement des utilisateurs:', error);
        console.log('📊 Fallback vers les données de test');
        
        // Utiliser les données de test en cas d'erreur
        userData = generateTestUsers();
        
        renderUsersTable();
        hideLoading();
        
        // Afficher un message à l'utilisateur
        showToast('Impossible de charger les utilisateurs Firebase. Affichage des données de test.', 'warning');
    }
}

function generateTestUsers() {
    return [
        {
            id: '1',
            name: 'Jean Dupont',
            email: 'jean.dupont@example.com',
            phone: '+237698123456',
            status: 'active',
            balance: 25000,
            createdAt: '2024-01-15T10:30:00Z',
            lastActivity: '2024-01-20T14:30:00Z'
        },
        {
            id: '2', 
            name: 'Marie Ngono',
            email: 'marie.ngono@example.com',
            phone: '+237677987654',
            status: 'active',
            balance: 15000,
            createdAt: '2024-01-10T09:15:00Z',
            lastActivity: '2024-01-19T16:45:00Z'
        },
        {
            id: '3',
            name: 'Paul Kamga', 
            email: 'paul.kamga@example.com',
            phone: '+237655445566',
            status: 'inactive',
            balance: 5000,
            createdAt: '2024-01-05T08:20:00Z',
            lastActivity: '2024-01-18T11:30:00Z'
        },
        {
            id: '4',
            name: 'Sophie Talla',
            email: 'sophie.talla@example.com', 
            phone: '+237699887766',
            status: 'blocked',
            balance: 0,
            createdAt: '2024-01-01T12:00:00Z',
            lastActivity: '2024-01-17T09:15:00Z'
        }
    ];
}

async function loadTransactionsData(filters = {}) {
    showLoading();
    
    try {
        // Si Firebase n'est pas disponible, utiliser des données de test
        if (typeof firebaseData === 'undefined' || !firebaseData) {
            console.log('📊 Utilisation de données de test pour les transactions');
            transactionData = generateTestTransactions();
        } else {
            // Charger les transactions réelles depuis Firebase
            const result = await firebaseData.getTransactions(50, null, filters);
            transactionData = result.transactions;
        }
        
        renderTransactionsTable();
        hideLoading();
    } catch (error) {
        console.error('❌ Erreur lors du chargement des transactions:', error);
        console.log('📊 Fallback vers les données de test');
        transactionData = generateTestTransactions();
        renderTransactionsTable();
        hideLoading();
    }
}

function generateTestTransactions() {
    return [
        {
            id: 'TXN001',
            userName: 'Jean Dupont',
            userEmail: 'jean.dupont@example.com',
            type: 'recharge',
            amount: 5000,
            status: 'completed',
            operator: 'MTN',
            createdAt: '2024-01-20T14:30:00Z'
        },
        {
            id: 'TXN002',
            userName: 'Marie Ngono',
            userEmail: 'marie.ngono@example.com',
            type: 'bundle',
            amount: 2500,
            status: 'pending',
            operator: 'Orange',
            createdAt: '2024-01-20T13:45:00Z'
        },
        {
            id: 'TXN003',
            userName: 'Paul Kamga',
            userEmail: 'paul.kamga@example.com',
            type: 'recharge',
            amount: 1000,
            status: 'failed',
            operator: 'Camtel',
            createdAt: '2024-01-20T12:15:00Z'
        }
    ];
}

async function loadRecentActivity() {
    try {
        // Charger l'activité récente depuis Firebase
        const activities = await firebaseData.getRecentActivity(10);
        
        // Formater les données pour l'affichage
        const formattedActivities = activities.map(activity => ({
            icon: getActivityIcon(activity.type),
            type: getActivityTypeClass(activity.type),
            message: activity.message,
            user: activity.userName || 'Utilisateur',
            time: formatTimeAgo(activity.timestamp)
        }));
        
        renderRecentActivity(formattedActivities);
    } catch (error) {
        console.error('❌ Erreur lors du chargement de l\'activité:', error);
        // Fallback avec données par défaut
        const defaultActivities = [
            {
                icon: 'fas fa-info-circle',
                type: 'info',
                message: 'Aucune activité récente',
                user: 'Système',
                time: 'Maintenant'
            }
        ];
        renderRecentActivity(defaultActivities);
    }
}

// ===============================
// Rendu des données
// ===============================
function renderUsersTable() {
    const tableBody = document.getElementById('usersTableBody');
    if (!tableBody) return;
    
    // Vider le tableau
    tableBody.innerHTML = '';
    
    if (!userData || userData.length === 0) {
        tableBody.innerHTML = `
            <tr>
                <td colspan="8" class="text-center">Aucun utilisateur trouvé</td>
            </tr>
        `;
        return;
    }
    
    userData.forEach(user => {
        const row = document.createElement('tr');
        
        // Construire l'avatar
        const avatar = user.photoURL 
            ? `<img src="${user.photoURL}" alt="${user.name}" class="profile-img">` 
            : `<div class="profile-img" style="background: var(--primary-color); color: white; display: flex; align-items: center; justify-content: center; font-weight: 600;">
                ${(user.name || 'U').charAt(0).toUpperCase()}
               </div>`;
        
        const statusClass = getStatusClass(user.status);
        const statusText = getStatusText(user.status);
        
        row.innerHTML = `
            <td>${avatar}</td>
            <td>${user.name || 'N/A'}</td>
            <td>${user.email || 'N/A'}</td>
            <td>${user.phone || 'N/A'}</td>
            <td>${formatCurrency(user.balance || 0)}</td>
            <td><span class="badge badge-${statusClass}">${statusText}</span></td>
            <td>${formatDate(user.createdAt) || 'N/A'}</td>
            <td>
                <button class="btn btn-sm btn-primary" onclick="viewUser('${user.id}')" title="Voir détails">
                    <i class="fas fa-eye"></i>
                </button>
                <button class="btn btn-sm btn-warning" onclick="editUser('${user.id}')" title="Modifier">
                    <i class="fas fa-edit"></i>
                </button>
                <button class="btn btn-sm ${user.status === 'active' ? 'btn-secondary' : 'btn-success'}" 
                        onclick="toggleUserStatus('${user.id}')" 
                        title="${user.status === 'active' ? 'Désactiver' : 'Activer'}">
                    <i class="fas fa-${user.status === 'active' ? 'pause' : 'play'}"></i>
                </button>
                <button class="btn btn-sm ${user.status === 'blocked' ? 'btn-info' : 'btn-warning'}" 
                        onclick="${user.status === 'blocked' ? 'unblockUser' : 'blockUser'}('${user.id}')" 
                        title="${user.status === 'blocked' ? 'Débloquer' : 'Bloquer'}">
                    <i class="fas fa-${user.status === 'blocked' ? 'unlock' : 'ban'}"></i>
                </button>
                <button class="btn btn-sm btn-danger" onclick="deleteUser('${user.id}')" title="Supprimer">
                    <i class="fas fa-trash"></i>
                </button>
            </td>
        `;
        
        tableBody.appendChild(row);
    });
}

function renderTransactionsTable() {
    const tableBody = document.getElementById('transactionsTableBody');
    if (!tableBody) return;
    
    // Vider le tableau
    tableBody.innerHTML = '';
    
    if (!transactionData || transactionData.length === 0) {
        tableBody.innerHTML = `
            <tr>
                <td colspan="7" class="text-center">Aucune transaction trouvée</td>
            </tr>
        `;
        return;
    }
    
    transactionData.forEach(transaction => {
        const row = document.createElement('tr');
        
        const statusClass = getStatusBadgeClass(transaction.status);
        const typeIcon = getTransactionTypeIcon(transaction.type);
        
        row.innerHTML = `
            <td><code>${transaction.id}</code></td>
            <td>${transaction.userName || transaction.userEmail || 'Utilisateur'}</td>
            <td>
                <i class="${typeIcon}"></i>
                ${formatTransactionType(transaction.type)}
            </td>
            <td class="font-weight-bold">${formatCurrency(transaction.amount || 0)}</td>
            <td><span class="badge badge-${statusClass}">${formatTransactionStatus(transaction.status)}</span></td>
            <td>${formatDate(transaction.createdAt) || 'N/A'}</td>
            <td>
                <button class="btn btn-sm btn-primary" onclick="viewTransaction('${transaction.id}')" title="Voir détails">
                    <i class="fas fa-eye"></i>
                </button>
                ${transaction.status === 'pending' ? 
                    `<button class="btn btn-sm btn-success" onclick="approveTransaction('${transaction.id}')" title="Approuver">
                        <i class="fas fa-check"></i>
                    </button>` : ''}
            </td>
        `;
        
        tableBody.appendChild(row);
    });
}

function renderRecentActivity(activities) {
    const activityList = document.getElementById('activity-list');
    if (!activityList) return;
    
    activityList.innerHTML = '';
    
    activities.forEach(activity => {
        const item = document.createElement('div');
        item.className = 'activity-item';
        item.innerHTML = `
            <div class="activity-icon ${activity.type}">
                <i class="${activity.icon}"></i>
            </div>
            <div class="activity-content">
                <p><strong>${activity.message}</strong></p>
                <p>${activity.user}</p>
                <small class="text-muted">${activity.time}</small>
            </div>
        `;
        activityList.appendChild(item);
    });
}

// ===============================
// Graphiques avec Chart.js
// ===============================
function initializeCharts() {
    // Les graphiques seront initialisés après le chargement des données
    console.log('🎯 Graphiques prêts à être initialisés');
}

// Charger les données des graphiques depuis Firebase
async function loadChartData() {
    try {
        // Charger les données de revenus
        const revenueData = await firebaseData.getRevenueChartData();
        initializeRevenueChart(revenueData);
        
        // Charger les données des utilisateurs
        const usersData = await firebaseData.getUsersChartData();
        initializeUsersChart(usersData);
        
    } catch (error) {
        console.error('❌ Erreur lors du chargement des graphiques:', error);
        // Initialiser avec des données par défaut
        initializeRevenueChart([0,0,0,0,0,0,0,0,0,0,0,0]);
        initializeUsersChart({ active: 0, inactive: 0, blocked: 0 });
    }
}

function initializeRevenueChart(monthlyData = []) {
    const ctx = document.getElementById('transactionsChart');
    if (!ctx) return;
    
    const data = {
        labels: ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'],
        datasets: [{
            label: 'Revenus (FCFA)',
            data: monthlyData.length === 12 ? monthlyData : [0,0,0,0,0,0,0,0,0,0,0,0],
            borderColor: 'rgb(79, 70, 229)',
            backgroundColor: 'rgba(79, 70, 229, 0.1)',
            borderWidth: 3,
            fill: true,
            tension: 0.4
        }]
    };
    
    const options = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                display: false
            },
            tooltip: {
                backgroundColor: 'rgba(0, 0, 0, 0.8)',
                titleColor: 'white',
                bodyColor: 'white',
                borderColor: 'rgba(79, 70, 229, 0.8)',
                borderWidth: 1
            }
        },
        scales: {
            y: {
                beginAtZero: true,
                ticks: {
                    callback: function(value) {
                        return formatCurrency(value);
                    }
                },
                grid: {
                    color: 'rgba(0, 0, 0, 0.1)'
                }
            },
            x: {
                grid: {
                    display: false
                }
            }
        }
    };
    
    charts.revenue = new Chart(ctx, {
        type: 'line',
        data: data,
        options: options
    });
}

function initializeUsersChart(usersData = {}) {
    const ctx = document.getElementById('servicesChart');
    if (!ctx) return;
    
    const data = {
        labels: ['Actifs', 'Inactifs', 'Bloqués'],
        datasets: [{
            data: [
                usersData.active || 0,
                usersData.inactive || 0,
                usersData.blocked || 0
            ],
            backgroundColor: [
                'rgb(16, 185, 129)',
                'rgb(245, 158, 11)',
                'rgb(239, 68, 68)'
            ],
            borderWidth: 0
        }]
    };
    
    const options = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                position: 'bottom',
                labels: {
                    padding: 20,
                    usePointStyle: true
                }
            }
        }
    };
    
    charts.users = new Chart(ctx, {
        type: 'doughnut',
        data: data,
        options: options
    });
}

// ===============================
// Actions Rapides
// ===============================
function handleQuickAction(action) {
    switch (action) {
        case 'add-user':
            showModal('user-modal');
            break;
        case 'export-users':
            exportData('users');
            break;
        case 'send-notification':
            showModal('notification-modal');
            break;
        case 'generate-report':
            generateReport();
            break;
        default:
            console.log('Action non définie:', action);
    }
}

function viewUser(userId) {
    const user = userData.find(u => u.id === userId);
    if (user) {
        showUserModal(user);
    }
}

let currentEditingUser = null;

function editUser(userId) {
    const user = userData.find(u => u.id === userId);
    if (user) {
        showEditUserModal(user);
    }
}

function showEditUserModal(user) {
    currentEditingUser = user;
    
    // Remplir le formulaire avec les données actuelles
    document.getElementById('editUserName').value = user.name || '';
    document.getElementById('editUserEmail').value = user.email || '';
    document.getElementById('editUserPhone').value = user.phone || '';
    document.getElementById('editUserBalance').value = user.balance || 0;
    document.getElementById('editUserStatus').value = user.status || 'active';
    
    showModal('editUserModal');
}

async function deleteUser(userId) {
    const user = userData.find(u => u.id === userId);
    if (!user) {
        showToast('Utilisateur introuvable', 'error');
        return;
    }
    
    if (!confirm(`Voulez-vous vraiment supprimer l'utilisateur "${user.name}" ?\n\nCette action est irréversible et supprimera aussi toutes ses données associées.`)) {
        return;
    }
    
    try {
        showLoading();
        
        // Si Firebase est disponible, supprimer depuis Firebase
        if (typeof firebaseData !== 'undefined' && firebaseData.deleteUser) {
            await firebaseData.deleteUser(userId);
        }
        
        // Supprimer de la liste locale
        const index = userData.findIndex(u => u.id === userId);
        if (index > -1) {
            userData.splice(index, 1);
        }
        
        showToast(`Utilisateur "${user.name}" supprimé avec succès`, 'success');
        renderUsersTable();
        hideLoading();
    } catch (error) {
        console.error('❌ Erreur lors de la suppression:', error);
        showToast('Erreur lors de la suppression de l\'utilisateur', 'error');
        hideLoading();
    }
}

async function toggleUserStatus(userId) {
    const user = userData.find(u => u.id === userId);
    if (!user) {
        showToast('Utilisateur introuvable', 'error');
        return;
    }
    
    const newStatus = user.status === 'active' ? 'inactive' : 'active';
    const action = newStatus === 'active' ? 'activer' : 'désactiver';
    
    if (!confirm(`Voulez-vous ${action} l'utilisateur "${user.name}" ?`)) {
        return;
    }
    
    try {
        showLoading();
        
        // Si Firebase est disponible, mettre à jour sur Firebase
        if (typeof firebaseData !== 'undefined' && firebaseData.updateUserStatus) {
            await firebaseData.updateUserStatus(userId, newStatus);
        }
        
        // Mettre à jour localement
        user.status = newStatus;
        
        showToast(`Utilisateur ${newStatus === 'active' ? 'activé' : 'désactivé'} avec succès`, 'success');
        renderUsersTable();
        hideLoading();
    } catch (error) {
        console.error('❌ Erreur lors de la modification du statut:', error);
        showToast('Erreur lors de la modification du statut', 'error');
        hideLoading();
    }
}

function viewTransaction(transactionId) {
    const transaction = transactionData.find(t => t.id === transactionId);
    if (transaction) {
        showTransactionModal(transaction);
    }
}

// ===============================
// Gestion des Modals
// ===============================
function showModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.add('show');
        document.body.style.overflow = 'hidden';
    }
}

function closeModal() {
    document.querySelectorAll('.modal').forEach(modal => {
        modal.classList.remove('show');
    });
    document.body.style.overflow = 'auto';
}

function showUserModal(user) {
    const modal = document.getElementById('user-modal');
    if (modal) {
        const modalBody = modal.querySelector('.modal-body');
        modalBody.innerHTML = `
            <div class="user-details">
                <h4>${user.name}</h4>
                <p><strong>Email:</strong> ${user.email}</p>
                <p><strong>Téléphone:</strong> ${user.phone}</p>
                <p><strong>Statut:</strong> ${user.status}</p>
                <p><strong>Solde:</strong> ${formatCurrency(user.balance)}</p>
                <p><strong>Dernière activité:</strong> ${formatDate(user.lastActivity)}</p>
            </div>
        `;
        showModal('user-modal');
    }
}

// ===============================
// Recherche
// ===============================
function handleSearch(event) {
    const query = event.target.value.toLowerCase();
    
    if (currentSection === 'users') {
        searchUsers(query);
    } else if (currentSection === 'transactions') {
        searchTransactions(query);
    }
}

function searchUsers(query) {
    const filteredUsers = userData.filter(user => 
        user.name.toLowerCase().includes(query) ||
        user.email.toLowerCase().includes(query) ||
        user.phone.includes(query)
    );
    
    // Re-render la table avec les résultats filtrés
    renderFilteredUsersTable(filteredUsers);
}

function searchTransactions(query) {
    const filteredTransactions = transactionData.filter(transaction => 
        transaction.id.toLowerCase().includes(query) ||
        transaction.user.toLowerCase().includes(query) ||
        transaction.type.toLowerCase().includes(query)
    );
    
    renderFilteredTransactionsTable(filteredTransactions);
}

// ===============================
// Utilitaires
// ===============================
function createDataTable(headers) {
    const table = document.createElement('table');
    table.className = 'data-table';
    
    const thead = document.createElement('thead');
    const headerRow = document.createElement('tr');
    
    headers.forEach(header => {
        const th = document.createElement('th');
        th.textContent = header;
        headerRow.appendChild(th);
    });
    
    thead.appendChild(headerRow);
    table.appendChild(thead);
    
    const tbody = document.createElement('tbody');
    table.appendChild(tbody);
    
    return table;
}

function formatNumber(num) {
    return new Intl.NumberFormat('fr-FR').format(num);
}

function formatCurrency(amount) {
    return new Intl.NumberFormat('fr-FR', {
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
    }).format(amount) + ' FCFA';
}

function formatDate(dateString) {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('fr-FR', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    }).format(date);
}

function getStatusBadgeClass(status) {
    const statusMap = {
        'Complété': 'success',
        'En cours': 'warning',
        'Échoué': 'danger',
        'Annulé': 'secondary'
    };
    return statusMap[status] || 'secondary';
}

function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

function showLoading() {
    isLoading = true;
    const loadingOverlay = document.getElementById('loading-overlay');
    if (loadingOverlay) {
        loadingOverlay.classList.add('show');
    }
}

function hideLoading() {
    isLoading = false;
    const loadingOverlay = document.getElementById('loading-overlay');
    if (loadingOverlay) {
        loadingOverlay.classList.remove('show');
    }
}

function exportData(type) {
    showLoading();
    
    setTimeout(() => {
        // Simuler l'export
        const filename = `merecharge-${type}-${new Date().toISOString().split('T')[0]}.csv`;
        console.log(`Export ${type} généré: ${filename}`);
        
        // Créer un toast de notification
        showToast(`Export ${type} téléchargé avec succès!`, 'success');
        hideLoading();
    }, 2000);
}

function generateReport() {
    showLoading();
    
    setTimeout(() => {
        const reportData = {
            period: 'Janvier 2024',
            totalUsers: 12847,
            totalRevenue: 2847203,
            totalTransactions: 8463
        };
        
        console.log('Rapport généré:', reportData);
        showToast('Rapport généré avec succès!', 'success');
        hideLoading();
    }, 3000);
}

function showToast(message, type = 'info', options = {}) {
    const {
        duration = 3000,
        position = 'top-right',
        showIcon = true,
        persistent = false,
        action = null
    } = options;
    
    // Icônes selon le type
    const icons = {
        'success': '✓',
        'error': '✗',
        'warning': '⚠',
        'info': 'i',
        'loading': '⏳'
    };
    
    // Couleurs selon le type
    const colors = {
        'success': '#10b981',
        'error': '#ef4444', 
        'warning': '#f59e0b',
        'info': '#3b82f6',
        'loading': '#6b7280'
    };
    
    // Positions possibles
    const positions = {
        'top-right': 'top: 20px; right: 20px;',
        'top-left': 'top: 20px; left: 20px;',
        'bottom-right': 'bottom: 20px; right: 20px;',
        'bottom-left': 'bottom: 20px; left: 20px;',
        'top-center': 'top: 20px; left: 50%; transform: translateX(-50%);',
        'bottom-center': 'bottom: 20px; left: 50%; transform: translateX(-50%);'
    };
    
    // Créer le toast
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.id = `toast-${Date.now()}`;
    
    // Contenu du toast
    let toastContent = '';
    if (showIcon) {
        toastContent += `<span class="toast-icon">${icons[type] || 'i'}</span>`;
    }
    toastContent += `<span class="toast-message">${message}</span>`;
    
    if (action) {
        toastContent += `<button class="toast-action" onclick="${action.callback}">${action.label}</button>`;
    }
    
    if (persistent) {
        toastContent += `<button class="toast-close" onclick="closeToast('${toast.id}')"><i class="fas fa-times"></i></button>`;
    }
    
    toast.innerHTML = toastContent;
    
    // Styles du toast
    const transformDirection = position.includes('right') ? 'translateX(100%)' : 
                              position.includes('left') ? 'translateX(-100%)' : 
                              position.includes('top') ? 'translateY(-100%)' : 'translateY(100%)';
    
    toast.style.cssText = `
        position: fixed;
        ${positions[position] || positions['top-right']}
        padding: 1rem 1.5rem;
        background: ${colors[type] || colors['info']};
        color: white;
        border-radius: 0.5rem;
        z-index: 9999;
        transform: ${transformDirection};
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
        display: flex;
        align-items: center;
        gap: 0.75rem;
        max-width: 350px;
        font-size: 0.9rem;
        border-left: 4px solid rgba(255, 255, 255, 0.3);
    `;
    
    // Styles pour les éléments internes
    const styleSheet = document.createElement('style');
    styleSheet.textContent = `
        .toast-icon {
            font-weight: bold;
            font-size: 1.1rem;
        }
        .toast-message {
            flex: 1;
        }
        .toast-action {
            background: rgba(255, 255, 255, 0.2);
            border: none;
            color: white;
            padding: 0.25rem 0.75rem;
            border-radius: 0.25rem;
            font-size: 0.8rem;
            cursor: pointer;
            transition: background 0.2s;
        }
        .toast-action:hover {
            background: rgba(255, 255, 255, 0.3);
        }
        .toast-close {
            background: none;
            border: none;
            color: rgba(255, 255, 255, 0.8);
            cursor: pointer;
            padding: 0.25rem;
            border-radius: 0.25rem;
            transition: all 0.2s;
        }
        .toast-close:hover {
            background: rgba(255, 255, 255, 0.2);
            color: white;
        }
    `;
    document.head.appendChild(styleSheet);
    
    document.body.appendChild(toast);
    
    // Animation d'entrée
    setTimeout(() => {
        toast.style.transform = position.includes('center') ? 
            (position.includes('top') ? 'translateX(-50%) translateY(0)' : 'translateX(-50%) translateY(0)') :
            'translateX(0) translateY(0)';
    }, 50);
    
    // Gérer la fermeture automatique
    if (!persistent) {
        setTimeout(() => {
            closeToast(toast.id);
        }, duration);
    }
    
    return toast.id;
}

function closeToast(toastId) {
    const toast = document.getElementById(toastId);
    if (toast) {
        const position = toast.style.right ? 'right' : toast.style.left ? 'left' : 'center';
        const transformOut = position === 'right' ? 'translateX(100%)' : 
                           position === 'left' ? 'translateX(-100%)' : 
                           toast.style.top ? 'translateY(-100%)' : 'translateY(100%)';
        
        toast.style.transform = transformOut;
        toast.style.opacity = '0';
        
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 300);
    }
}

// Raccourcis pour différents types de toast
function showSuccessToast(message, options = {}) {
    return showToast(message, 'success', options);
}

function showErrorToast(message, options = {}) {
    return showToast(message, 'error', options);
}

function showWarningToast(message, options = {}) {
    return showToast(message, 'warning', options);
}

function showLoadingToast(message, options = {}) {
    return showToast(message, 'loading', { persistent: true, ...options });
}

// ===============================
// Fonctions spécifiques aux sections
// ===============================
// ===============================
// Section Recharges
// ===============================
let rechargeData = [];

async function loadRechargesData(filters = {}) {
    showLoading();
    
    try {
        // Charger les recharges réelles depuis Firebase
        const result = await firebaseData.getRecharges(50, null, filters);
        rechargeData = result.recharges;
        
        // Mettre à jour les statistiques des recharges
        await updateRechargesStats();
        
        renderRechargesTable();
        hideLoading();
    } catch (error) {
        console.error('❌ Erreur lors du chargement des recharges:', error);
        showToast('Erreur lors du chargement des recharges', 'error');
        hideLoading();
    }
}

async function updateRechargesStats() {
    try {
        // Calculer les statistiques
        const totalCount = rechargeData.length;
        const totalAmount = rechargeData.reduce((sum, r) => sum + (r.amount || 0), 0);
        const pendingCount = rechargeData.filter(r => r.status === 'pending').length;
        const failedCount = rechargeData.filter(r => r.status === 'failed').length;
        
        // Mettre à jour l'interface
        updateStatCard('totalRechargesCount', totalCount);
        updateStatCard('totalRechargesAmount', formatCurrency(totalAmount));
        updateStatCard('pendingRechargesCount', pendingCount);
        updateStatCard('failedRechargesCount', failedCount);
    } catch (error) {
        console.error('❌ Erreur lors de la mise à jour des stats:', error);
    }
}

function renderRechargesTable() {
    const tableBody = document.getElementById('rechargesTableBody');
    if (!tableBody) return;
    
    // Vider le tableau
    tableBody.innerHTML = '';
    
    if (!rechargeData || rechargeData.length === 0) {
        tableBody.innerHTML = `
            <tr>
                <td colspan="9" class="text-center">Aucune recharge trouvée</td>
            </tr>
        `;
        return;
    }
    
    rechargeData.forEach(recharge => {
        const row = document.createElement('tr');
        
        const statusClass = getStatusBadgeClass(recharge.status);
        const operatorIcon = getOperatorIcon(recharge.operator);
        
        row.innerHTML = `
            <td><code>${recharge.id}</code></td>
            <td>${recharge.userName || recharge.userEmail || 'Utilisateur'}</td>
            <td>
                <i class="${operatorIcon}" style="color: ${getOperatorColor(recharge.operator)}"></i>
                ${recharge.operator}
            </td>
            <td>${recharge.phoneNumber || 'N/A'}</td>
            <td class="font-weight-bold">${formatCurrency(recharge.amount || 0)}</td>
            <td><span class="badge badge-${statusClass}">${formatTransactionStatus(recharge.status)}</span></td>
            <td><code>${recharge.reference || 'N/A'}</code></td>
            <td>${formatDate(recharge.createdAt) || 'N/A'}</td>
            <td>
                <button class="btn btn-sm btn-primary" onclick="viewRecharge('${recharge.id}')" title="Voir détails">
                    <i class="fas fa-eye"></i>
                </button>
                ${recharge.status === 'pending' ? 
                    `<button class="btn btn-sm btn-success" onclick="retryRecharge('${recharge.id}')" title="Relancer">
                        <i class="fas fa-redo"></i>
                    </button>` : ''}
            </td>
        `;
        
        tableBody.appendChild(row);
    });
}

// ===============================
// Section Commandes
// ===============================
let orderData = [];

async function loadOrdersData(filters = {}) {
    showLoading();
    
    try {
        // Charger les commandes réelles depuis Firebase
        const result = await firebaseData.getOrders(50, null, filters);
        orderData = result.orders;
        
        renderOrdersTable();
        hideLoading();
    } catch (error) {
        console.error('❌ Erreur lors du chargement des commandes:', error);
        showToast('Erreur lors du chargement des commandes', 'error');
        hideLoading();
    }
}

function renderOrdersTable() {
    const tableBody = document.getElementById('ordersTableBody');
    if (!tableBody) return;
    
    // Vider le tableau
    tableBody.innerHTML = '';
    
    if (!orderData || orderData.length === 0) {
        tableBody.innerHTML = `
            <tr>
                <td colspan="7" class="text-center">Aucune commande trouvée</td>
            </tr>
        `;
        return;
    }
    
    orderData.forEach(order => {
        const row = document.createElement('tr');
        
        const statusClass = getStatusBadgeClass(order.status);
        const itemsCount = order.items ? order.items.length : 0;
        const itemsText = itemsCount === 1 ? '1 produit' : `${itemsCount} produits`;
        
        row.innerHTML = `
            <td><code>${order.id}</code></td>
            <td>${order.userName || order.userEmail || 'Client'}</td>
            <td>${itemsText}</td>
            <td class="font-weight-bold">${formatCurrency(order.total || 0)}</td>
            <td><span class="badge badge-${statusClass}">${formatOrderStatus(order.status)}</span></td>
            <td>${formatDate(order.createdAt) || 'N/A'}</td>
            <td>
                <button class="btn btn-sm btn-primary" onclick="viewOrder('${order.id}')" title="Voir détails">
                    <i class="fas fa-eye"></i>
                </button>
                ${order.status === 'pending' ? 
                    `<button class="btn btn-sm btn-success" onclick="processOrder('${order.id}')" title="Traiter">
                        <i class="fas fa-check"></i>
                    </button>` : ''}
            </td>
        `;
        
        tableBody.appendChild(row);
    });
}

// ===============================
// Section Produits
// ===============================
let productData = [];
let currentEditingProduct = null;

async function loadProductsData(categoryFilter = null) {
    showLoading();
    
    try {
        // Si Firebase n'est pas disponible, utiliser des données de test
        if (typeof firebaseData === 'undefined' || !firebaseData) {
            console.log('📊 Utilisation de données de test pour les produits');
            productData = generateTestProducts();
        } else {
            // Charger les produits réels depuis Firebase
            productData = await firebaseData.getProducts();
        }
        
        // Filtrer par catégorie si nécessaire
        if (categoryFilter) {
            productData = productData.filter(p => p.category === categoryFilter);
        }
        
        renderProductsGrid();
        hideLoading();
    } catch (error) {
        console.error('❌ Erreur lors du chargement des produits:', error);
        console.log('📊 Fallback vers les données de test');
        productData = generateTestProducts();
        
        // Filtrer par catégorie si nécessaire
        if (categoryFilter) {
            productData = productData.filter(p => p.category === categoryFilter);
        }
        
        renderProductsGrid();
        hideLoading();
    }
}

function generateTestProducts() {
    return [
        {
            id: 'PROD001',
            name: 'Modem 4G TP-Link',
            description: 'Modem 4G portable avec batterie longue durée, compatible tous opérateurs',
            price: 85000,
            category: 'modems',
            brand: 'TP-Link',
            stock: 15,
            isActive: true,
            createdAt: '2024-01-15T10:00:00Z'
        },
        {
            id: 'PROD002',
            name: 'Laptop HP EliteBook 840',
            description: 'Ordinateur portable professionnel, Intel i5, 8GB RAM, 256GB SSD',
            price: 450000,
            category: 'laptops',
            brand: 'HP',
            stock: 8,
            isActive: true,
            createdAt: '2024-01-14T15:30:00Z'
        },
        {
            id: 'PROD003',
            name: 'Routeur Wi-Fi Cisco',
            description: 'Routeur Wi-Fi 6 dual-band, portée étendue, sécurité avancée',
            price: 125000,
            category: 'routeurs',
            brand: 'Cisco',
            stock: 0,
            isActive: false,
            createdAt: '2024-01-12T09:15:00Z'
        },
        {
            id: 'PROD004',
            name: 'Smartphone Samsung Galaxy A54',
            description: 'Smartphone Android, 128GB, caméra 50MP, écran AMOLED 6.4"',
            price: 285000,
            category: 'smartphones',
            brand: 'Samsung',
            stock: 22,
            isActive: true,
            createdAt: '2024-01-10T14:20:00Z'
        },
        {
            id: 'PROD005',
            name: 'Câble USB-C Premium',
            description: 'Câble USB-C vers USB-A, charge rapide, transfert de données 3.0',
            price: 3500,
            category: 'accessoires',
            brand: 'Anker',
            stock: 45,
            isActive: true,
            createdAt: '2024-01-08T11:30:00Z'
        },
        {
            id: 'PROD006',
            name: 'Laptop Dell Inspiron 15',
            description: 'Ordinateur portable étudiant/bureautique, AMD Ryzen 5, 16GB RAM',
            price: 375000,
            category: 'laptops',
            brand: 'Dell',
            stock: 12,
            isActive: true,
            createdAt: '2024-01-05T16:45:00Z'
        }
    ];
}

function renderProductsGrid() {
    const grid = document.getElementById('productsGrid');
    if (!grid) return;
    
    // Vider la grille
    grid.innerHTML = '';
    
    if (!productData || productData.length === 0) {
        grid.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-laptop" style="font-size: 3rem; color: var(--text-tertiary); margin-bottom: 1rem;"></i>
                <h3>Aucun produit électronique trouvé</h3>
                <p>Commencez par ajouter votre premier produit (modem, laptop, routeur, smartphone...)</p>
                <button class="btn btn-primary" onclick="showAddProductModal()">
                    <i class="fas fa-plus"></i>
                    Ajouter un produit
                </button>
            </div>
        `;
        return;
    }
    
    // Style CSS pour la grille
    grid.style.display = 'grid';
    grid.style.gridTemplateColumns = 'repeat(auto-fill, minmax(300px, 1fr))';
    grid.style.gap = '1.5rem';
    
    productData.forEach(product => {
        const card = document.createElement('div');
        card.className = 'product-card';
        
        const statusClass = product.isActive ? 'success' : 'secondary';
        const statusText = product.isActive ? 'Actif' : 'Inactif';
        
        card.innerHTML = `
            <div class="product-card-header">
                <h4>${product.name}</h4>
                <span class="badge badge-${statusClass}">${statusText}</span>
            </div>
            <div class="product-card-body">
                <p class="product-description">${product.description || 'Aucune description'}</p>
                <div class="product-info">
                    <div class="product-price">${formatCurrency(product.price || 0)}</div>
                    <div class="product-category">
                        <i class="fas fa-tag"></i>
                        ${formatProductCategory(product.category)}
                    </div>
                    ${product.brand ? 
                        `<div class="product-brand">
                            <i class="fas fa-industry"></i>
                            ${product.brand}
                        </div>` : ''}
                    ${typeof product.stock !== 'undefined' ? 
                        `<div class="product-stock">
                            <i class="fas fa-boxes"></i>
                            ${product.stock > 0 ? `${product.stock} en stock` : 'Rupture de stock'}
                        </div>` : ''}
                </div>
            </div>
            <div class="product-card-actions">
                <button class="btn btn-sm btn-primary" onclick="editProduct('${product.id}')">
                    <i class="fas fa-edit"></i>
                    Modifier
                </button>
                <button class="btn btn-sm btn-warning" onclick="toggleProductStatus('${product.id}')">
                    <i class="fas fa-${product.isActive ? 'pause' : 'play'}"></i>
                    ${product.isActive ? 'Désactiver' : 'Activer'}
                </button>
                <button class="btn btn-sm btn-danger" onclick="deleteProduct('${product.id}')">
                    <i class="fas fa-trash"></i>
                    Supprimer
                </button>
            </div>
        `;
        
        grid.appendChild(card);
    });
}

// ===============================
// Section Notifications
// ===============================
async function loadNotificationsData() {
    // Cette section utilise déjà les éléments du HTML
    console.log('🔔 Section Notifications prête');
    setupNotificationHandlers();
}

function setupNotificationHandlers() {
    // Gestion du formulaire de notification
    const sendBtn = document.getElementById('sendNotificationSubmit');
    if (sendBtn) {
        sendBtn.addEventListener('click', handleSendNotification);
    }
    
    // Gestion des templates
    const templateSelect = document.getElementById('notificationTemplate');
    if (templateSelect) {
        templateSelect.addEventListener('change', function() {
            const template = this.value;
            if (template) {
                fillNotificationTemplate(template);
            }
        });
    }
    
    // Gestion du type de notification
    const typeSelect = document.getElementById('notificationType');
    if (typeSelect) {
        typeSelect.addEventListener('change', function() {
            const isTargeted = this.value === 'targeted';
            toggleTargetedOptions(isTargeted);
        });
    }
}

function toggleTargetedOptions(isTargeted) {
    // Implémentation future pour le ciblage d'utilisateurs spécifiques
    console.log('Type de notification:', isTargeted ? 'Ciblée' : 'Générale');
}

function fillNotificationTemplate(templateType) {
    const templates = {
        'maintenance': {
            title: '🔧 Maintenance Programmée',
            message: 'Notre service sera temporairement indisponible le [DATE] de [HEURE_DEBUT] à [HEURE_FIN] pour une maintenance. Merci de votre compréhension.'
        },
        'promotion': {
            title: '🎉 Promotion Spéciale !',
            message: 'Profitez de notre offre exceptionnelle : [DETAILS_PROMO]. Offre valable jusqu\'au [DATE_FIN]. Ne manquez pas cette opportunité !'
        },
        'nouveau_produit': {
            title: '📱 Nouveau Produit Disponible',
            message: 'Découvrez notre nouveau produit [NOM_PRODUIT] maintenant disponible ! [DESCRIPTION_COURTE]. Commandez dès maintenant dans l\'application.'
        },
        'mise_a_jour': {
            title: '⬆️ Mise à Jour Disponible',
            message: 'Une nouvelle version de MeRecharge est disponible ! Nouvelles fonctionnalités : [FONCTIONNALITES]. Mettez à jour dès maintenant.'
        },
        'felicitations': {
            title: '🎊 Félicitations !',
            message: 'Félicitations [NOM_USER] ! Vous avez atteint [ACCOMPLISSEMENT]. Continuez ainsi et découvrez nos récompenses exclusives.'
        },
        'rappel_paiement': {
            title: '💳 Rappel de Paiement',
            message: 'Votre commande [NUMERO_COMMANDE] est en attente de paiement. Montant : [MONTANT] FCFA. Complétez votre achat avant [DATE_LIMITE].'
        },
        'bienvenue': {
            title: '🎉 Bienvenue sur MeRecharge !',
            message: 'Bienvenue [NOM_USER] ! Merci d\'avoir rejoint MeRecharge. Découvrez tous nos services : recharges, produits électroniques et bien plus !'
        }
    };
    
    const template = templates[templateType];
    if (template) {
        document.getElementById('notificationTitle').value = template.title;
        document.getElementById('notificationMessage').value = template.message;
        
        // Animation pour montrer que le template a été appliqué
        const titleInput = document.getElementById('notificationTitle');
        const messageTextarea = document.getElementById('notificationMessage');
        
        titleInput.style.backgroundColor = '#e7f3ff';
        messageTextarea.style.backgroundColor = '#e7f3ff';
        
        setTimeout(() => {
            titleInput.style.backgroundColor = '';
            messageTextarea.style.backgroundColor = '';
        }, 1000);
        
        showToast(`Template "${templateType}" appliqué ! N'oubliez pas de personnaliser les variables.`, 'info');
    }
}

async function handleSendNotification() {
    const title = document.getElementById('notificationTitle').value.trim();
    const message = document.getElementById('notificationMessage').value.trim();
    const type = document.getElementById('notificationType').value;
    
    if (!title || !message) {
        showToast('Veuillez remplir le titre et le message', 'warning');
        return;
    }
    
    try {
        showLoading();
        
        if (type === 'broadcast') {
            // Envoyer à tous les utilisateurs
            await firebaseData.sendNotificationToAll(title, message, {
                type: 'admin_broadcast',
                timestamp: Date.now()
            });
            
            showToast('Notification envoyée à tous les utilisateurs', 'success');
        } else {
            // Implémentation future pour notifications ciblées
            showToast('Fonctionnalité de ciblage en développement', 'info');
        }
        
        // Réinitialiser le formulaire
        document.getElementById('notificationTitle').value = '';
        document.getElementById('notificationMessage').value = '';
        
        hideLoading();
    } catch (error) {
        console.error('❌ Erreur lors de l\'envoi:', error);
        showToast('Erreur lors de l\'envoi de la notification', 'error');
        hideLoading();
    }
}

// ===============================
// Section Rapports
// ===============================
let reportsData = {
    period: 30,
    revenue: 0,
    users: 0,
    transactions: 0,
    successRate: 0,
    trends: {},
    charts: {}
};

async function loadReportsData() {
    const period = parseInt(document.getElementById('reportPeriod')?.value) || 30;
    
    showLoading();
    
    try {
        // Charger les données de rapport
        await generateReportsData(period);
        
        // Mettre à jour l'interface
        updateReportsKPIs();
        
        // Initialiser les graphiques
        initializeReportsCharts();
        
        // Charger les tops listes
        await loadTopPerformers();
        
        hideLoading();
    } catch (error) {
        console.error('❌ Erreur lors du chargement des rapports:', error);
        showToast('Erreur lors du chargement des rapports', 'error');
        hideLoading();
    }
}

async function generateReportsData(periodDays) {
    try {
        const endDate = new Date();
        const startDate = new Date();
        startDate.setDate(startDate.getDate() - periodDays);
        
        // Charger les transactions pour la période
        const transactionsResult = await firebaseData.getTransactions(1000, null, {
            dateFrom: startDate.toISOString(),
            dateTo: endDate.toISOString()
        });
        
        const transactions = transactionsResult.transactions;
        
        // Calculer les KPIs
        const totalRevenue = transactions
            .filter(t => t.status === 'completed')
            .reduce((sum, t) => sum + (t.amount || 0), 0);
            
        const completedTransactions = transactions.filter(t => t.status === 'completed').length;
        const totalTransactions = transactions.length;
        const successRate = totalTransactions > 0 ? (completedTransactions / totalTransactions) * 100 : 0;
        
        // Obtenir les utilisateurs uniques
        const uniqueUsers = new Set(transactions.map(t => t.userId)).size;
        
        // Calculer les tendances (comparaison avec la période précédente)
        const prevStartDate = new Date(startDate);
        prevStartDate.setDate(prevStartDate.getDate() - periodDays);
        
        const prevTransactionsResult = await firebaseData.getTransactions(1000, null, {
            dateFrom: prevStartDate.toISOString(),
            dateTo: startDate.toISOString()
        });
        
        const prevTransactions = prevTransactionsResult.transactions;
        const prevRevenue = prevTransactions
            .filter(t => t.status === 'completed')
            .reduce((sum, t) => sum + (t.amount || 0), 0);
        const prevUsers = new Set(prevTransactions.map(t => t.userId)).size;
        const prevCompletedTransactions = prevTransactions.filter(t => t.status === 'completed').length;
        
        // Calculer les pourcentages de variation
        const revenueTrend = prevRevenue > 0 ? ((totalRevenue - prevRevenue) / prevRevenue) * 100 : 0;
        const usersTrend = prevUsers > 0 ? ((uniqueUsers - prevUsers) / prevUsers) * 100 : 0;
        const transactionsTrend = prevCompletedTransactions > 0 ? 
            ((completedTransactions - prevCompletedTransactions) / prevCompletedTransactions) * 100 : 0;
        
        // Générer les données pour les graphiques
        const dailyData = generateDailyRevenueData(transactions, startDate, endDate);
        const operatorData = generateOperatorDistribution(transactions);
        
        // Mettre à jour l'objet global
        reportsData = {
            period: periodDays,
            revenue: totalRevenue,
            users: uniqueUsers,
            transactions: completedTransactions,
            successRate: Math.round(successRate),
            trends: {
                revenue: revenueTrend,
                users: usersTrend,
                transactions: transactionsTrend,
                successRate: 0 // Calculé différemment si nécessaire
            },
            charts: {
                daily: dailyData,
                operators: operatorData
            }
        };
        
    } catch (error) {
        console.error('❌ Erreur lors de la génération des rapports:', error);
        throw error;
    }
}

function generateDailyRevenueData(transactions, startDate, endDate) {
    const dailyData = {};
    const currentDate = new Date(startDate);
    
    // Initialiser tous les jours avec 0
    while (currentDate <= endDate) {
        const dateStr = currentDate.toISOString().split('T')[0];
        dailyData[dateStr] = 0;
        currentDate.setDate(currentDate.getDate() + 1);
    }
    
    // Additionner les revenus par jour
    transactions
        .filter(t => t.status === 'completed')
        .forEach(transaction => {
            if (transaction.createdAt) {
                const date = new Date(transaction.createdAt).toISOString().split('T')[0];
                if (dailyData.hasOwnProperty(date)) {
                    dailyData[date] += transaction.amount || 0;
                }
            }
        });
    
    return {
        labels: Object.keys(dailyData).map(date => new Date(date).toLocaleDateString('fr-FR', { 
            month: 'short', 
            day: 'numeric' 
        })),
        data: Object.values(dailyData)
    };
}

function generateOperatorDistribution(transactions) {
    const operatorData = {};
    
    transactions
        .filter(t => t.status === 'completed' && t.operator)
        .forEach(transaction => {
            const operator = transaction.operator;
            if (!operatorData[operator]) {
                operatorData[operator] = 0;
            }
            operatorData[operator] += transaction.amount || 0;
        });
    
    return {
        labels: Object.keys(operatorData),
        data: Object.values(operatorData),
        colors: Object.keys(operatorData).map(op => getOperatorColor(op))
    };
}

function updateReportsKPIs() {
    // Mettre à jour les KPIs
    updateStatCard('reportTotalRevenue', formatCurrency(reportsData.revenue));
    updateStatCard('reportActiveUsers', reportsData.users);
    updateStatCard('reportTotalTransactions', reportsData.transactions);
    updateStatCard('reportSuccessRate', reportsData.successRate + '%');
    
    // Mettre à jour les tendances
    updateTrend('reportRevenueTrend', 
        (reportsData.trends.revenue > 0 ? '+' : '') + Math.round(reportsData.trends.revenue) + '%', 
        reportsData.trends.revenue >= 0);
        
    updateTrend('reportUsersTrend', 
        (reportsData.trends.users > 0 ? '+' : '') + Math.round(reportsData.trends.users) + '%', 
        reportsData.trends.users >= 0);
        
    updateTrend('reportTransactionsTrend', 
        (reportsData.trends.transactions > 0 ? '+' : '') + Math.round(reportsData.trends.transactions) + '%', 
        reportsData.trends.transactions >= 0);
}

function initializeReportsCharts() {
    initializeRevenueEvolutionChart();
    initializeOperatorDistributionChart();
}

function initializeRevenueEvolutionChart() {
    const ctx = document.getElementById('revenueEvolutionChart');
    if (!ctx || !reportsData.charts.daily) return;
    
    const data = {
        labels: reportsData.charts.daily.labels,
        datasets: [{
            label: 'Chiffre d\'affaires (FCFA)',
            data: reportsData.charts.daily.data,
            borderColor: 'rgb(79, 70, 229)',
            backgroundColor: 'rgba(79, 70, 229, 0.1)',
            borderWidth: 3,
            fill: true,
            tension: 0.4
        }]
    };
    
    const options = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                display: false
            }
        },
        scales: {
            y: {
                beginAtZero: true,
                ticks: {
                    callback: function(value) {
                        return formatCurrency(value);
                    }
                }
            }
        }
    };
    
    new Chart(ctx, {
        type: 'line',
        data: data,
        options: options
    });
}

function initializeOperatorDistributionChart() {
    const ctx = document.getElementById('operatorDistributionChart');
    if (!ctx || !reportsData.charts.operators) return;
    
    const data = {
        labels: reportsData.charts.operators.labels,
        datasets: [{
            data: reportsData.charts.operators.data,
            backgroundColor: reportsData.charts.operators.colors,
            borderWidth: 0
        }]
    };
    
    const options = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                position: 'bottom'
            }
        }
    };
    
    new Chart(ctx, {
        type: 'doughnut',
        data: data,
        options: options
    });
}

async function loadTopPerformers() {
    try {
        // Top utilisateurs (simuler pour l'instant)
        const topUsers = [
            { name: 'Jean Dupont', transactions: 45, revenue: 125000 },
            { name: 'Marie Ngono', transactions: 38, revenue: 98000 },
            { name: 'Paul Kamga', transactions: 32, revenue: 87000 },
            { name: 'Sophie Talla', transactions: 28, revenue: 76000 },
            { name: 'Eric Biya', transactions: 25, revenue: 65000 }
        ];
        
        // Top produits (simuler pour l'instant)
        const topProducts = [
            { name: 'Forfait MTN 1GB', sales: 234, revenue: 585000 },
            { name: 'Recharge Orange 1000', sales: 189, revenue: 189000 },
            { name: 'Forfait Orange 2GB', sales: 156, revenue: 468000 },
            { name: 'Recharge MTN 500', sales: 145, revenue: 72500 },
            { name: 'Forfait Camtel 5GB', sales: 98, revenue: 490000 }
        ];
        
        renderTopUsers(topUsers);
        renderTopProducts(topProducts);
        
    } catch (error) {
        console.error('❌ Erreur lors du chargement des top performers:', error);
    }
}

function renderTopUsers(users) {
    const container = document.getElementById('topUsersList');
    if (!container) return;
    
    container.innerHTML = users.map((user, index) => `
        <div class="top-item">
            <div class="top-rank">#${index + 1}</div>
            <div class="top-info">
                <div class="top-name">${user.name}</div>
                <div class="top-details">${user.transactions} transactions • ${formatCurrency(user.revenue)}</div>
            </div>
        </div>
    `).join('');
}

function renderTopProducts(products) {
    const container = document.getElementById('topProductsList');
    if (!container) return;
    
    container.innerHTML = products.map((product, index) => `
        <div class="top-item">
            <div class="top-rank">#${index + 1}</div>
            <div class="top-info">
                <div class="top-name">${product.name}</div>
                <div class="top-details">${product.sales} ventes • ${formatCurrency(product.revenue)}</div>
            </div>
        </div>
    `).join('');
}

// Event listeners pour les rapports
document.addEventListener('DOMContentLoaded', function() {
    // Actualiser les rapports
    const refreshBtn = document.getElementById('refreshReportsBtn');
    if (refreshBtn) {
        refreshBtn.addEventListener('click', loadReportsData);
    }
    
    // Changement de période
    const periodSelect = document.getElementById('reportPeriod');
    if (periodSelect) {
        periodSelect.addEventListener('change', loadReportsData);
    }
    
    // Export PDF
    const exportBtn = document.getElementById('exportReportBtn');
    if (exportBtn) {
        exportBtn.addEventListener('click', exportReportToPDF);
    }
});

async function exportReportToPDF() {
    try {
        showLoading();
        
        // Simuler la génération PDF
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        const filename = `rapport-merecharge-${new Date().toISOString().split('T')[0]}.pdf`;
        showToast(`Rapport exporté: ${filename}`, 'success');
        
        hideLoading();
    } catch (error) {
        console.error('❌ Erreur lors de l\'export PDF:', error);
        showToast('Erreur lors de l\'export PDF', 'error');
        hideLoading();
    }
}

function loadSettingsData() {
    console.log('Chargement des paramètres...');
    // Implementation future
}

// ===============================
// Gestion des erreurs globales
// ===============================
window.addEventListener('error', function(e) {
    console.error('Erreur JavaScript:', e.error);
    showToast('Une erreur est survenue. Veuillez rafraîchir la page.', 'error');
});

// ===============================
// Service Worker pour le cache (optionnel)
// ===============================
if ('serviceWorker' in navigator) {
    window.addEventListener('load', function() {
        navigator.serviceWorker.register('/sw.js')
            .then(function(registration) {
                console.log('ServiceWorker registered successfully');
            })
            .catch(function(registrationError) {
                console.log('ServiceWorker registration failed');
            });
    });
}

// ===============================
// Fonctions utilitaires pour opérateurs
// ===============================
function getOperatorIcon(operator) {
    const iconMap = {
        'MTN': 'fas fa-mobile-alt',
        'Orange': 'fas fa-mobile-alt', 
        'Camtel': 'fas fa-phone',
        'Nexttel': 'fas fa-mobile-alt'
    };
    return iconMap[operator] || 'fas fa-mobile-alt';
}

function getOperatorColor(operator) {
    const colorMap = {
        'MTN': '#ffcc00',
        'Orange': '#ff6600',
        'Camtel': '#00cc66',
        'Nexttel': '#cc0066'
    };
    return colorMap[operator] || 'var(--primary-color)';
}

function formatProductCategory(category) {
    const categoryMap = {
        'modems': 'Modems',
        'laptops': 'Laptops',
        'routeurs': 'Routeurs',
        'smartphones': 'Smartphones',
        'accessoires': 'Accessoires'
    };
    return categoryMap[category] || category;
}

function formatOrderStatus(status) {
    const statusMap = {
        'pending': 'En attente',
        'processing': 'En cours',
        'completed': 'Terminée',
        'cancelled': 'Annulée',
        'delivered': 'Livrée'
    };
    return statusMap[status] || status;
}

// ===============================
// Actions pour les recharges
// ===============================
async function viewRecharge(rechargeId) {
    try {
        const recharge = rechargeData.find(r => r.id === rechargeId);
        if (!recharge) {
            showToast('Recharge introuvable', 'error');
            return;
        }
        
        const modal = document.getElementById('rechargeDetailsModal');
        const content = document.getElementById('rechargeDetailsContent');
        
        content.innerHTML = `
            <div class="details-grid">
                <div class="detail-item">
                    <label>ID de la recharge:</label>
                    <span><code>${recharge.id}</code></span>
                </div>
                <div class="detail-item">
                    <label>Utilisateur:</label>
                    <span>${recharge.userName || recharge.userEmail || 'N/A'}</span>
                </div>
                <div class="detail-item">
                    <label>Opérateur:</label>
                    <span>
                        <i class="${getOperatorIcon(recharge.operator)}" style="color: ${getOperatorColor(recharge.operator)}"></i>
                        ${recharge.operator}
                    </span>
                </div>
                <div class="detail-item">
                    <label>Numéro:</label>
                    <span>${recharge.phoneNumber || 'N/A'}</span>
                </div>
                <div class="detail-item">
                    <label>Montant:</label>
                    <span class="font-weight-bold">${formatCurrency(recharge.amount)}</span>
                </div>
                <div class="detail-item">
                    <label>Statut:</label>
                    <span><span class="badge badge-${getStatusBadgeClass(recharge.status)}">${formatTransactionStatus(recharge.status)}</span></span>
                </div>
                <div class="detail-item">
                    <label>Référence:</label>
                    <span><code>${recharge.reference || 'N/A'}</code></span>
                </div>
                <div class="detail-item">
                    <label>Date de création:</label>
                    <span>${formatDate(recharge.createdAt)}</span>
                </div>
                ${recharge.updatedAt ? `
                    <div class="detail-item">
                        <label>Dernière modification:</label>
                        <span>${formatDate(recharge.updatedAt)}</span>
                    </div>
                ` : ''}
                ${recharge.errorMessage ? `
                    <div class="detail-item">
                        <label>Message d'erreur:</label>
                        <span class="text-danger">${recharge.errorMessage}</span>
                    </div>
                ` : ''}
            </div>
        `;
        
        showModal('rechargeDetailsModal');
    } catch (error) {
        console.error('❌ Erreur lors de l\'affichage des détails:', error);
        showToast('Erreur lors du chargement des détails', 'error');
    }
}

async function retryRecharge(rechargeId) {
    if (!confirm('Voulez-vous relancer cette recharge ?')) return;
    
    try {
        // Implémentation de la relance de recharge
        console.log('Relance de la recharge:', rechargeId);
        showToast('Recharge relancée avec succès', 'success');
        loadRechargesData(); // Recharger la liste
    } catch (error) {
        console.error('❌ Erreur lors de la relance:', error);
        showToast('Erreur lors de la relance', 'error');
    }
}

// ===============================
// Actions pour les commandes
// ===============================
async function viewOrder(orderId) {
    try {
        const order = orderData.find(o => o.id === orderId);
        if (!order) {
            showToast('Commande introuvable', 'error');
            return;
        }
        
        const modal = document.getElementById('orderDetailsModal');
        const content = document.getElementById('orderDetailsContent');
        
        let itemsHtml = '';
        if (order.items && order.items.length > 0) {
            itemsHtml = order.items.map(item => `
                <div class="order-item">
                    <span class="item-name">${item.name}</span>
                    <span class="item-quantity">x${item.quantity}</span>
                    <span class="item-price">${formatCurrency(item.price)}</span>
                </div>
            `).join('');
        }
        
        content.innerHTML = `
            <div class="details-grid">
                <div class="detail-item">
                    <label>ID de la commande:</label>
                    <span><code>${order.id}</code></span>
                </div>
                <div class="detail-item">
                    <label>Client:</label>
                    <span>${order.userName || order.userEmail || 'N/A'}</span>
                </div>
                <div class="detail-item">
                    <label>Statut:</label>
                    <span><span class="badge badge-${getStatusBadgeClass(order.status)}">${formatOrderStatus(order.status)}</span></span>
                </div>
                <div class="detail-item">
                    <label>Total:</label>
                    <span class="font-weight-bold">${formatCurrency(order.total)}</span>
                </div>
                <div class="detail-item">
                    <label>Date de commande:</label>
                    <span>${formatDate(order.createdAt)}</span>
                </div>
            </div>
            
            ${order.items && order.items.length > 0 ? `
                <div class="order-items-section">
                    <h4>Articles commandés</h4>
                    <div class="order-items-list">
                        ${itemsHtml}
                    </div>
                </div>
            ` : ''}
        `;
        
        showModal('orderDetailsModal');
    } catch (error) {
        console.error('❌ Erreur lors de l\'affichage des détails:', error);
        showToast('Erreur lors du chargement des détails', 'error');
    }
}

async function processOrder(orderId) {
    if (!confirm('Voulez-vous traiter cette commande ?')) return;
    
    try {
        // Implémentation du traitement de commande
        console.log('Traitement de la commande:', orderId);
        showToast('Commande mise en traitement', 'success');
        loadOrdersData(); // Recharger la liste
    } catch (error) {
        console.error('❌ Erreur lors du traitement:', error);
        showToast('Erreur lors du traitement', 'error');
    }
}

// ===============================
// Actions pour les produits
// ===============================
function showAddProductModal() {
    currentEditingProduct = null;
    document.getElementById('productModalTitle').textContent = 'Nouveau Produit';
    document.getElementById('productForm').reset();
    showModal('productModal');
}

async function editProduct(productId) {
    try {
        const product = productData.find(p => p.id === productId);
        if (!product) {
            showToast('Produit introuvable', 'error');
            return;
        }
        
        currentEditingProduct = product;
        document.getElementById('productModalTitle').textContent = 'Modifier le Produit';
        
        // Remplir le formulaire
        document.getElementById('productName').value = product.name || '';
        document.getElementById('productDescription').value = product.description || '';
        document.getElementById('productPrice').value = product.price || '';
        document.getElementById('productCategory').value = product.category || '';
        document.getElementById('productBrand').value = product.brand || '';
        document.getElementById('productStock').value = product.stock || 0;
        document.getElementById('productIsActive').checked = product.isActive !== false;
        
        showModal('productModal');
    } catch (error) {
        console.error('❌ Erreur lors de l\'ouverture du produit:', error);
        showToast('Erreur lors du chargement du produit', 'error');
    }
}

async function toggleProductStatus(productId) {
    try {
        const product = productData.find(p => p.id === productId);
        if (!product) {
            showToast('Produit introuvable', 'error');
            return;
        }
        
        const newStatus = !product.isActive;
        const action = newStatus ? 'activer' : 'désactiver';
        
        if (!confirm(`Voulez-vous ${action} ce produit ?`)) return;
        
        await firebaseData.updateProduct(productId, { isActive: newStatus });
        showToast(`Produit ${newStatus ? 'activé' : 'désactivé'} avec succès`, 'success');
        loadProductsData(); // Recharger la liste
    } catch (error) {
        console.error('❌ Erreur lors de la modification:', error);
        showToast('Erreur lors de la modification', 'error');
    }
}

async function deleteProduct(productId) {
    if (!confirm('Voulez-vous vraiment supprimer ce produit ? Cette action est irréversible.')) return;
    
    try {
        await firebaseData.deleteProduct(productId);
        showToast('Produit supprimé avec succès', 'success');
        loadProductsData(); // Recharger la liste
    } catch (error) {
        console.error('❌ Erreur lors de la suppression:', error);
        showToast('Erreur lors de la suppression', 'error');
    }
}

// Gestion du formulaire de modification utilisateur
document.addEventListener('DOMContentLoaded', function() {
    const editUserForm = document.getElementById('editUserForm');
    if (editUserForm) {
        editUserForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            if (!currentEditingUser) {
                showToast('Erreur: Aucun utilisateur sélectionné', 'error');
                return;
            }
            
            const formData = {
                name: document.getElementById('editUserName').value.trim(),
                email: document.getElementById('editUserEmail').value.trim(),
                phone: document.getElementById('editUserPhone').value.trim(),
                balance: parseFloat(document.getElementById('editUserBalance').value) || 0,
                status: document.getElementById('editUserStatus').value
            };
            
            // Validation basique
            if (!formData.name || !formData.email) {
                showToast('Nom et email sont obligatoires', 'warning');
                return;
            }
            
            try {
                showLoading();
                
                // Si Firebase est disponible, mettre à jour sur Firebase
                if (typeof firebaseData !== 'undefined' && firebaseData.updateUser) {
                    await firebaseData.updateUser(currentEditingUser.id, formData);
                }
                
                // Mettre à jour localement
                Object.assign(currentEditingUser, formData);
                
                showToast('Utilisateur modifié avec succès', 'success');
                closeModal();
                renderUsersTable();
                hideLoading();
            } catch (error) {
                console.error('❌ Erreur lors de la modification:', error);
                showToast('Erreur lors de la modification de l\'utilisateur', 'error');
                hideLoading();
            }
        });
    }
    
    // Gestion du formulaire de produit
    const productForm = document.getElementById('productForm');
    if (productForm) {
        productForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const formData = {
                name: document.getElementById('productName').value,
                description: document.getElementById('productDescription').value,
                price: parseFloat(document.getElementById('productPrice').value) || 0,
                category: document.getElementById('productCategory').value,
                brand: document.getElementById('productBrand').value || null,
                stock: parseInt(document.getElementById('productStock').value) || 0,
                isActive: document.getElementById('productIsActive').checked
            };
            
            try {
                if (currentEditingProduct) {
                    // Modification
                    await firebaseData.updateProduct(currentEditingProduct.id, formData);
                    showToast('Produit modifié avec succès', 'success');
                } else {
                    // Création
                    await firebaseData.addProduct(formData);
                    showToast('Produit ajouté avec succès', 'success');
                }
                
                closeModal();
                loadProductsData(); // Recharger la liste
            } catch (error) {
                console.error('❌ Erreur lors de l\'enregistrement:', error);
                showToast('Erreur lors de l\'enregistrement', 'error');
            }
        });
    }
});

// ===============================
// Fonctions utilitaires pour le formatage
// ===============================
function getStatusClass(status) {
    const statusMap = {
        'active': 'success',
        'inactive': 'warning', 
        'blocked': 'danger',
        'suspended': 'secondary'
    };
    return statusMap[status] || 'secondary';
}

function getStatusText(status) {
    const statusMap = {
        'active': 'Actif',
        'inactive': 'Inactif',
        'blocked': 'Bloqué',
        'suspended': 'Suspendu'
    };
    return statusMap[status] || 'Inconnu';
}

function getTransactionTypeIcon(type) {
    const iconMap = {
        'recharge': 'fas fa-mobile-alt',
        'bundle': 'fas fa-wifi',
        'deposit': 'fas fa-arrow-down',
        'withdraw': 'fas fa-arrow-up',
        'transfer': 'fas fa-exchange-alt',
        'payment': 'fas fa-credit-card'
    };
    return iconMap[type] || 'fas fa-coins';
}

function formatTransactionType(type) {
    const typeMap = {
        'recharge': 'Recharge',
        'bundle': 'Forfait',
        'deposit': 'Dépôt',
        'withdraw': 'Retrait',
        'transfer': 'Transfert',
        'payment': 'Paiement'
    };
    return typeMap[type] || type;
}

function formatTransactionStatus(status) {
    const statusMap = {
        'pending': 'En attente',
        'completed': 'Terminée',
        'failed': 'Échouée',
        'cancelled': 'Annulée'
    };
    return statusMap[status] || status;
}

// Actions utilisateur supplémentaires
async function blockUser(userId) {
    const user = userData.find(u => u.id === userId);
    if (!user) {
        showToast('Utilisateur introuvable', 'error');
        return;
    }
    
    if (!confirm(`Voulez-vous bloquer l'utilisateur "${user.name}" ?\n\nL'utilisateur ne pourra plus accéder à l'application.`)) {
        return;
    }
    
    try {
        showLoading();
        
        // Si Firebase est disponible, mettre à jour sur Firebase
        if (typeof firebaseData !== 'undefined' && firebaseData.updateUserStatus) {
            await firebaseData.updateUserStatus(userId, 'blocked');
        }
        
        // Mettre à jour localement
        user.status = 'blocked';
        
        showToast(`Utilisateur "${user.name}" bloqué avec succès`, 'success');
        renderUsersTable();
        hideLoading();
    } catch (error) {
        console.error('❌ Erreur lors du blocage:', error);
        showToast('Erreur lors du blocage de l\'utilisateur', 'error');
        hideLoading();
    }
}

async function unblockUser(userId) {
    const user = userData.find(u => u.id === userId);
    if (!user) {
        showToast('Utilisateur introuvable', 'error');
        return;
    }
    
    if (!confirm(`Voulez-vous débloquer l'utilisateur "${user.name}" ?`)) {
        return;
    }
    
    try {
        showLoading();
        
        // Si Firebase est disponible, mettre à jour sur Firebase
        if (typeof firebaseData !== 'undefined' && firebaseData.updateUserStatus) {
            await firebaseData.updateUserStatus(userId, 'active');
        }
        
        // Mettre à jour localement
        user.status = 'active';
        
        showToast(`Utilisateur "${user.name}" débloqué avec succès`, 'success');
        renderUsersTable();
        hideLoading();
    } catch (error) {
        console.error('❌ Erreur lors du déblocage:', error);
        showToast('Erreur lors du déblocage de l\'utilisateur', 'error');
        hideLoading();
    }
}

async function approveTransaction(transactionId) {
    if (!confirm('Voulez-vous approuver cette transaction ?')) return;
    
    try {
        // Implémentation de l'approbation
        console.log('Approbation de la transaction:', transactionId);
        showToast('Transaction approuvée', 'success');
        loadTransactionsData(); // Recharger la liste
    } catch (error) {
        console.error('❌ Erreur lors de l\'approbation:', error);
        showToast('Erreur lors de l\'approbation', 'error');
    }
}

// ===============================
// Fonctions utilitaires pour l'activité
// ===============================
function getActivityIcon(type) {
    const iconMap = {
        'user_registered': 'fas fa-user-plus',
        'transaction_completed': 'fas fa-credit-card',
        'transaction_failed': 'fas fa-exclamation-triangle',
        'recharge_completed': 'fas fa-mobile-alt',
        'order_placed': 'fas fa-shopping-cart',
        'user_blocked': 'fas fa-user-slash'
    };
    return iconMap[type] || 'fas fa-info-circle';
}

function getActivityTypeClass(type) {
    const typeMap = {
        'user_registered': 'success',
        'transaction_completed': 'success',
        'transaction_failed': 'warning',
        'recharge_completed': 'success',
        'order_placed': 'info',
        'user_blocked': 'danger'
    };
    return typeMap[type] || 'info';
}

function formatTimeAgo(timestamp) {
    if (!timestamp) return 'Maintenant';
    
    const now = new Date();
    const time = new Date(timestamp);
    const diff = Math.floor((now - time) / 1000);
    
    if (diff < 60) return 'Il y a quelques secondes';
    if (diff < 3600) return `Il y a ${Math.floor(diff / 60)} minutes`;
    if (diff < 86400) return `Il y a ${Math.floor(diff / 3600)} heures`;
    return `Il y a ${Math.floor(diff / 86400)} jours`;
}

// ===============================
// Authentification
// ===============================
function checkAuthState() {
    if (typeof adminAuth !== 'undefined') {
        adminAuth.onAuthStateChanged((admin) => {
            if (!admin) {
                // Rediriger vers la page de connexion ou afficher modal
                showLoginModal();
            } else {
                updateAdminProfile(admin);
            }
        });
    }
}

function showLoginModal() {
    // Implémentation de la modal de connexion
    console.log('🔒 Admin non connecté - Affichage de la modal de connexion');
}

function updateAdminProfile(admin) {
    const adminName = document.querySelector('.admin-name');
    if (adminName && admin.name) {
        adminName.textContent = admin.name;
    }
}

// ===============================
// Initialisation avec authentification
// ===============================
document.addEventListener('DOMContentLoaded', function() {
    // Vérifier d'abord si Firebase est disponible
    if (typeof firebase !== 'undefined') {
        checkAuthState();
    }
});

console.log('🎯 MeRecharge Admin Dashboard - Scripts chargés avec succès!');
