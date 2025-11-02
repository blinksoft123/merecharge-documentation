// ===============================
// Configuration et Variables
// ===============================
const API_BASE_URL = 'http://localhost:3000/api';
const API_KEY = 'votre_cle_api_secrete'; // À synchroniser avec le backend

// État global de l'application
let currentSection = 'dashboard';
let charts = {};
let intervals = {};

// ===============================
// Utilitaires
// ===============================
const Utils = {
    formatNumber: (num) => new Intl.NumberFormat('fr-FR').format(num),
    formatCurrency: (amount) => `${new Intl.NumberFormat('fr-FR').format(amount)} XAF`,
    formatDateTime: (dateStr) => new Intl.DateTimeFormat('fr-FR', {
        year: 'numeric', month: 'short', day: 'numeric',
        hour: '2-digit', minute: '2-digit'
    }).format(new Date(dateStr)),
    formatDate: (dateStr) => new Intl.DateTimeFormat('fr-FR').format(new Date(dateStr)),
    
    showLoading: () => document.getElementById('loadingModal').classList.add('show'),
    hideLoading: () => document.getElementById('loadingModal').classList.remove('show'),
    
    showToast: (message, type = 'info') => {
        // Implémentation simple de toast notification
        const toast = document.createElement('div');
        toast.className = `toast toast-${type}`;
        toast.textContent = message;
        toast.style.cssText = `
            position: fixed; top: 20px; right: 20px; z-index: 3000;
            padding: 1rem 1.5rem; border-radius: 8px; color: white;
            background: ${type === 'success' ? '#28a745' : type === 'error' ? '#dc3545' : '#667eea'};
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        `;
        document.body.appendChild(toast);
        setTimeout(() => {
            toast.style.opacity = '0';
            setTimeout(() => document.body.removeChild(toast), 300);
        }, 3000);
    }
};

// ===============================
// API Service
// ===============================
const API = {
    headers: {
        'Content-Type': 'application/json',
        'X-API-Key': API_KEY
    },

    async request(endpoint, options = {}) {
        try {
            const response = await fetch(`${API_BASE_URL}${endpoint}`, {
                headers: this.headers,
                ...options
            });
            
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            
            return await response.json();
        } catch (error) {
            console.error('API Request Error:', error);
            throw error;
        }
    },

    // Endpoints spécifiques
    ping: () => API.request('/ping'),
    getServices: () => API.request('/services'),
    getTopupProducts: (serviceId) => API.request(`/topup/${serviceId}`),
    getVoucherProducts: (serviceId) => API.request(`/voucher/${serviceId}`),
    verifyTransaction: (transactionId) => API.request(`/verify/${transactionId}`),
    
    // CallBox Sync
    getSyncStatus: () => API.request('/sync/status'),
    startSync: () => API.request('/sync/start', { method: 'POST' }),
    stopSync: () => API.request('/sync/stop', { method: 'POST' }),
    forceSync: () => API.request('/sync/force', { method: 'POST' }),
    
    // Transactions
    recharge: (data) => API.request('/recharge', {
        method: 'POST',
        body: JSON.stringify(data)
    }),
    
    purchaseVoucher: (data) => API.request('/voucher', {
        method: 'POST',
        body: JSON.stringify(data)
    }),
    
    deposit: (data) => API.request('/deposit', {
        method: 'POST',
        body: JSON.stringify(data)
    }),
    
    withdraw: (data) => API.request('/withdraw', {
        method: 'POST',
        body: JSON.stringify(data)
    })
};

// ===============================
// Navigation et UI
// ===============================
const Navigation = {
    init() {
        this.bindEvents();
        this.checkServerStatus();
        setInterval(() => this.checkServerStatus(), 30000); // Vérifier toutes les 30 secondes
    },

    bindEvents() {
        // Navigation dans la sidebar
        document.querySelectorAll('.nav-link').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const section = e.currentTarget.dataset.section;
                this.switchSection(section);
            });
        });

        // Toggle sidebar sur mobile
        document.getElementById('sidebarToggle')?.addEventListener('click', () => {
            document.getElementById('sidebar').classList.toggle('open');
        });

        // Déconnexion
        document.getElementById('logoutBtn')?.addEventListener('click', () => {
            if (confirm('Êtes-vous sûr de vouloir vous déconnecter ?')) {
                window.location.href = 'login.html';
            }
        });
    },

    switchSection(section) {
        // Masquer toutes les sections
        document.querySelectorAll('.content-section').forEach(s => {
            s.classList.remove('active');
        });

        // Afficher la section demandée
        document.getElementById(`${section}-section`).classList.add('active');

        // Mettre à jour la navigation
        document.querySelectorAll('.nav-link').forEach(link => {
            link.classList.remove('active');
        });
        document.querySelector(`[data-section="${section}"]`).classList.add('active');

        currentSection = section;

        // Charger les données de la section
        this.loadSectionData(section);
    },

    async loadSectionData(section) {
        switch (section) {
            case 'dashboard':
                await Dashboard.loadData();
                break;
            case 'transactions':
                await Transactions.loadData();
                break;
            case 'services':
                await Services.loadData();
                break;
            case 'callbox':
                await CallBox.loadData();
                break;
            case 'reports':
                await Reports.loadData();
                break;
        }
    },

    async checkServerStatus() {
        try {
            await API.ping();
            document.getElementById('serverStatus').classList.remove('offline');
            document.getElementById('serverStatusText').textContent = 'Serveur En ligne';
        } catch (error) {
            document.getElementById('serverStatus').classList.add('offline');
            document.getElementById('serverStatusText').textContent = 'Serveur Hors ligne';
        }
    }
};

// ===============================
// Dashboard Principal
// ===============================
const Dashboard = {
    init() {
        this.bindEvents();
        this.loadData();
        // Actualiser les données toutes les 5 minutes
        intervals.dashboard = setInterval(() => this.loadData(), 300000);
    },

    bindEvents() {
        document.getElementById('refreshDashboard')?.addEventListener('click', () => {
            this.loadData();
        });
    },

    async loadData() {
        try {
            Utils.showLoading();
            
            // Simuler des données (à remplacer par de vraies données depuis une base de données)
            const stats = await this.generateMockStats();
            
            this.updateStats(stats);
            this.updateCharts(stats);
            this.updateRecentActivity();
            
        } catch (error) {
            console.error('Erreur lors du chargement du dashboard:', error);
            Utils.showToast('Erreur lors du chargement des données', 'error');
        } finally {
            Utils.hideLoading();
        }
    },

    async generateMockStats() {
        // Générer des statistiques factices
        // Dans un vrai projet, ces données viendraient d'une base de données
        const today = new Date();
        return {
            totalTransactions: Math.floor(Math.random() * 150) + 50,
            successfulTransactions: Math.floor(Math.random() * 140) + 45,
            failedTransactions: Math.floor(Math.random() * 10) + 2,
            totalRevenue: Math.floor(Math.random() * 500000) + 100000,
            hourlyData: Array.from({length: 24}, (_, i) => ({
                hour: i,
                transactions: Math.floor(Math.random() * 20)
            })),
            typeData: {
                recharge: Math.floor(Math.random() * 50) + 20,
                voucher: Math.floor(Math.random() * 30) + 10,
                deposit: Math.floor(Math.random() * 20) + 5,
                withdraw: Math.floor(Math.random() * 15) + 3
            }
        };
    },

    updateStats(stats) {
        document.getElementById('totalTransactions').textContent = Utils.formatNumber(stats.totalTransactions);
        document.getElementById('successfulTransactions').textContent = Utils.formatNumber(stats.successfulTransactions);
        document.getElementById('failedTransactions').textContent = Utils.formatNumber(stats.failedTransactions);
        document.getElementById('totalRevenue').textContent = Utils.formatCurrency(stats.totalRevenue);
    },

    updateCharts(stats) {
        this.createTransactionsChart(stats.hourlyData);
        this.createTypeChart(stats.typeData);
    },

    createTransactionsChart(data) {
        const ctx = document.getElementById('transactionsChart');
        if (charts.transactions) charts.transactions.destroy();

        charts.transactions = new Chart(ctx, {
            type: 'line',
            data: {
                labels: data.map(d => `${d.hour}h`),
                datasets: [{
                    label: 'Transactions par Heure',
                    data: data.map(d => d.transactions),
                    borderColor: '#667eea',
                    backgroundColor: 'rgba(102, 126, 234, 0.1)',
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false }
                },
                scales: {
                    y: { beginAtZero: true }
                }
            }
        });
    },

    createTypeChart(data) {
        const ctx = document.getElementById('typeChart');
        if (charts.type) charts.type.destroy();

        charts.type = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['Recharge', 'Forfait', 'Dépôt', 'Retrait'],
                datasets: [{
                    data: [data.recharge, data.voucher, data.deposit, data.withdraw],
                    backgroundColor: ['#28a745', '#667eea', '#17a2b8', '#ffc107']
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { position: 'bottom' }
                }
            }
        });
    },

    updateRecentActivity() {
        const activities = [
            {
                type: 'success',
                icon: 'fas fa-check-circle',
                title: 'Recharge réussie',
                description: 'Recharge de 1000 XAF pour +237670123456',
                time: '2 minutes'
            },
            {
                type: 'warning',
                icon: 'fas fa-exclamation-triangle',
                title: 'Synchronisation CallBox',
                description: 'Nouvelle synchronisation en cours',
                time: '5 minutes'
            },
            {
                type: 'success',
                icon: 'fas fa-money-bill',
                title: 'Achat de forfait',
                description: 'Forfait 7 jours pour +237681234567',
                time: '8 minutes'
            },
            {
                type: 'error',
                icon: 'fas fa-times-circle',
                title: 'Transaction échouée',
                description: 'Retrait de 5000 XAF - Solde insuffisant',
                time: '12 minutes'
            }
        ];

        const activityList = document.getElementById('recentActivity');
        activityList.innerHTML = activities.map(activity => `
            <div class="activity-item">
                <div class="activity-icon ${activity.type}">
                    <i class="${activity.icon}"></i>
                </div>
                <div class="activity-content">
                    <h6>${activity.title}</h6>
                    <p>${activity.description}</p>
                    <span class="activity-time">Il y a ${activity.time}</span>
                </div>
            </div>
        `).join('');
    }
};

// ===============================
// Gestion des Transactions
// ===============================
const Transactions = {
    currentPage: 1,
    itemsPerPage: 10,
    transactions: [],

    init() {
        this.bindEvents();
    },

    bindEvents() {
        document.getElementById('searchTransactions')?.addEventListener('click', () => {
            this.loadData();
        });
    },

    async loadData(page = 1) {
        try {
            Utils.showLoading();
            
            // Simuler des données de transaction
            this.transactions = this.generateMockTransactions();
            this.currentPage = page;
            
            this.renderTransactions();
            this.renderPagination();
            
        } catch (error) {
            console.error('Erreur lors du chargement des transactions:', error);
            Utils.showToast('Erreur lors du chargement des transactions', 'error');
        } finally {
            Utils.hideLoading();
        }
    },

    generateMockTransactions() {
        const types = ['recharge', 'voucher', 'deposit', 'withdraw'];
        const statuses = ['success', 'error', 'pending'];
        const transactions = [];

        for (let i = 0; i < 50; i++) {
            transactions.push({
                id: `TXN${String(i + 1).padStart(6, '0')}`,
                type: types[Math.floor(Math.random() * types.length)],
                phoneNumber: `+237${Math.floor(Math.random() * 900000000) + 600000000}`,
                amount: Math.floor(Math.random() * 10000) + 500,
                status: statuses[Math.floor(Math.random() * statuses.length)],
                date: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000)
            });
        }

        return transactions.sort((a, b) => b.date - a.date);
    },

    renderTransactions() {
        const startIndex = (this.currentPage - 1) * this.itemsPerPage;
        const endIndex = startIndex + this.itemsPerPage;
        const pageTransactions = this.transactions.slice(startIndex, endIndex);

        const tbody = document.getElementById('transactionsTableBody');
        tbody.innerHTML = pageTransactions.map(tx => `
            <tr>
                <td>${tx.id}</td>
                <td><span class="status-badge ${tx.type}">${this.getTypeLabel(tx.type)}</span></td>
                <td>${tx.phoneNumber}</td>
                <td>${Utils.formatCurrency(tx.amount)}</td>
                <td><span class="status-badge ${tx.status}">${this.getStatusLabel(tx.status)}</span></td>
                <td>${Utils.formatDateTime(tx.date)}</td>
                <td>
                    <button class="btn btn-primary" onclick="Transactions.viewTransaction('${tx.id}')">
                        <i class="fas fa-eye"></i>
                    </button>
                    ${tx.status === 'pending' ? `
                        <button class="btn btn-success" onclick="Transactions.verifyTransaction('${tx.id}')">
                            <i class="fas fa-check"></i>
                        </button>
                    ` : ''}
                </td>
            </tr>
        `).join('');
    },

    renderPagination() {
        const totalPages = Math.ceil(this.transactions.length / this.itemsPerPage);
        const pagination = document.getElementById('transactionsPagination');

        let paginationHTML = '';
        
        // Bouton Précédent
        if (this.currentPage > 1) {
            paginationHTML += `<button onclick="Transactions.loadData(${this.currentPage - 1})">Précédent</button>`;
        }

        // Numéros de page
        for (let i = 1; i <= totalPages; i++) {
            if (i === this.currentPage) {
                paginationHTML += `<button class="active">${i}</button>`;
            } else {
                paginationHTML += `<button onclick="Transactions.loadData(${i})">${i}</button>`;
            }
        }

        // Bouton Suivant
        if (this.currentPage < totalPages) {
            paginationHTML += `<button onclick="Transactions.loadData(${this.currentPage + 1})">Suivant</button>`;
        }

        pagination.innerHTML = paginationHTML;
    },

    getTypeLabel(type) {
        const labels = {
            recharge: 'Recharge',
            voucher: 'Forfait',
            deposit: 'Dépôt',
            withdraw: 'Retrait'
        };
        return labels[type] || type;
    },

    getStatusLabel(status) {
        const labels = {
            success: 'Réussie',
            error: 'Échouée',
            pending: 'En attente'
        };
        return labels[status] || status;
    },

    async viewTransaction(transactionId) {
        try {
            Utils.showLoading();
            // Dans un vrai projet, récupérer les détails de la transaction
            const transaction = this.transactions.find(tx => tx.id === transactionId);
            
            if (transaction) {
                alert(`Détails de la transaction ${transactionId}:\n\nType: ${this.getTypeLabel(transaction.type)}\nMontant: ${Utils.formatCurrency(transaction.amount)}\nStatut: ${this.getStatusLabel(transaction.status)}\nDate: ${Utils.formatDateTime(transaction.date)}`);
            }
        } catch (error) {
            Utils.showToast('Erreur lors de la récupération des détails', 'error');
        } finally {
            Utils.hideLoading();
        }
    },

    async verifyTransaction(transactionId) {
        try {
            Utils.showLoading();
            const result = await API.verifyTransaction(transactionId);
            Utils.showToast('Transaction vérifiée avec succès', 'success');
            this.loadData(this.currentPage);
        } catch (error) {
            Utils.showToast('Erreur lors de la vérification', 'error');
        } finally {
            Utils.hideLoading();
        }
    }
};

// ===============================
// Gestion des Services
// ===============================
const Services = {
    services: [],

    init() {
        this.bindEvents();
    },

    bindEvents() {
        document.getElementById('refreshServices')?.addEventListener('click', () => {
            this.loadData();
        });
    },

    async loadData() {
        try {
            Utils.showLoading();
            this.services = await API.getServices();
            this.renderServices();
        } catch (error) {
            console.error('Erreur lors du chargement des services:', error);
            Utils.showToast('Erreur lors du chargement des services', 'error');
        } finally {
            Utils.hideLoading();
        }
    },

    renderServices() {
        const grid = document.getElementById('servicesGrid');
        grid.innerHTML = this.services.map(service => `
            <div class="service-card">
                <h4>${service.name || service.id}</h4>
                <span class="service-status active">Actif</span>
                <p><strong>ID:</strong> ${service.id}</p>
                <p><strong>Code:</strong> ${service.code || 'N/A'}</p>
                <div class="service-actions">
                    <button class="btn btn-primary" onclick="Services.viewProducts('${service.id}', 'topup')">
                        <i class="fas fa-mobile-alt"></i> Voir Recharges
                    </button>
                    <button class="btn btn-info" onclick="Services.viewProducts('${service.id}', 'voucher')">
                        <i class="fas fa-ticket-alt"></i> Voir Forfaits
                    </button>
                </div>
            </div>
        `).join('');
    },

    async viewProducts(serviceId, type) {
        try {
            Utils.showLoading();
            let products;
            
            if (type === 'topup') {
                products = await API.getTopupProducts(serviceId);
            } else {
                products = await API.getVoucherProducts(serviceId);
            }
            
            this.showProductsModal(products, type);
        } catch (error) {
            Utils.showToast(`Erreur lors du chargement des ${type === 'topup' ? 'recharges' : 'forfaits'}`, 'error');
        } finally {
            Utils.hideLoading();
        }
    },

    showProductsModal(products, type) {
        const title = type === 'topup' ? 'Produits de Recharge' : 'Forfaits Disponibles';
        const productsList = products.map(product => `
            <div style="padding: 10px; border-bottom: 1px solid #eee;">
                <strong>${product.name || product.id}</strong><br>
                <span>Prix: ${Utils.formatCurrency(product.amount || product.price || 0)}</span><br>
                <small>ID: ${product.id}</small>
            </div>
        `).join('');

        const modal = document.createElement('div');
        modal.className = 'modal show';
        modal.innerHTML = `
            <div class="modal-content" style="max-width: 500px;">
                <h3>${title}</h3>
                <div style="max-height: 400px; overflow-y: auto; margin: 1rem 0;">
                    ${productsList}
                </div>
                <button class="btn btn-primary" onclick="document.body.removeChild(this.closest('.modal'))">
                    Fermer
                </button>
            </div>
        `;

        document.body.appendChild(modal);
    }
};

// ===============================
// Gestion CallBox
// ===============================
const CallBox = {
    init() {
        this.bindEvents();
    },

    bindEvents() {
        document.getElementById('startSync')?.addEventListener('click', () => this.startSync());
        document.getElementById('stopSync')?.addEventListener('click', () => this.stopSync());
        document.getElementById('forceSync')?.addEventListener('click', () => this.forceSync());
    },

    async loadData() {
        try {
            Utils.showLoading();
            const status = await API.getSyncStatus();
            this.updateSyncStatus(status);
        } catch (error) {
            console.error('Erreur lors du chargement des données CallBox:', error);
            Utils.showToast('Erreur lors du chargement des données CallBox', 'error');
        } finally {
            Utils.hideLoading();
        }
    },

    updateSyncStatus(status) {
        const statusInfo = document.getElementById('syncStatusInfo');
        const lastSyncInfo = document.getElementById('lastSyncInfo');

        statusInfo.innerHTML = `
            <p><strong>Statut:</strong> ${status.syncStatus?.running ? 'En cours' : 'Arrêté'}</p>
            <p><strong>Dernière activité:</strong> ${Utils.formatDateTime(new Date())}</p>
        `;

        lastSyncInfo.innerHTML = `
            <p><strong>Dernière sync:</strong> ${Utils.formatDateTime(new Date())}</p>
            <p><strong>Transactions synchronisées:</strong> ${Math.floor(Math.random() * 50)}</p>
        `;

        this.updateSyncLogs();
    },

    updateSyncLogs() {
        const logs = [
            `[${new Date().toISOString()}] INFO: Service de synchronisation démarré`,
            `[${new Date(Date.now() - 60000).toISOString()}] INFO: Connexion à CallBox établie`,
            `[${new Date(Date.now() - 120000).toISOString()}] INFO: 15 transactions synchronisées`,
            `[${new Date(Date.now() - 180000).toISOString()}] WARNING: Délai de connexion élevé`,
            `[${new Date(Date.now() - 240000).toISOString()}] INFO: Synchronisation automatique en cours`
        ];

        document.getElementById('syncLogs').innerHTML = logs.join('\n');
    },

    async startSync() {
        try {
            Utils.showLoading();
            await API.startSync();
            Utils.showToast('Service de synchronisation démarré', 'success');
            this.loadData();
        } catch (error) {
            Utils.showToast('Erreur lors du démarrage de la synchronisation', 'error');
        } finally {
            Utils.hideLoading();
        }
    },

    async stopSync() {
        try {
            Utils.showLoading();
            await API.stopSync();
            Utils.showToast('Service de synchronisation arrêté', 'success');
            this.loadData();
        } catch (error) {
            Utils.showToast('Erreur lors de l\'arrêt de la synchronisation', 'error');
        } finally {
            Utils.hideLoading();
        }
    },

    async forceSync() {
        try {
            Utils.showLoading();
            await API.forceSync();
            Utils.showToast('Synchronisation forcée exécutée', 'success');
            this.loadData();
        } catch (error) {
            Utils.showToast('Erreur lors de la synchronisation forcée', 'error');
        } finally {
            Utils.hideLoading();
        }
    }
};

// ===============================
// Rapports
// ===============================
const Reports = {
    init() {
        this.bindEvents();
        this.setDefaultDates();
    },

    bindEvents() {
        document.getElementById('generateReport')?.addEventListener('click', () => {
            this.generateReport();
        });
    },

    setDefaultDates() {
        const today = new Date();
        const weekAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
        
        document.getElementById('reportStartDate').value = weekAgo.toISOString().split('T')[0];
        document.getElementById('reportEndDate').value = today.toISOString().split('T')[0];
    },

    async loadData() {
        this.generateReport();
    },

    async generateReport() {
        try {
            Utils.showLoading();
            
            const startDate = document.getElementById('reportStartDate').value;
            const endDate = document.getElementById('reportEndDate').value;
            
            if (!startDate || !endDate) {
                Utils.showToast('Veuillez sélectionner les dates de début et de fin', 'error');
                return;
            }

            // Générer des données de rapport simulées
            const reportData = this.generateMockReportData(startDate, endDate);
            
            this.createRevenueChart(reportData.revenue);
            this.createVolumeChart(reportData.volume);
            
        } catch (error) {
            console.error('Erreur lors de la génération du rapport:', error);
            Utils.showToast('Erreur lors de la génération du rapport', 'error');
        } finally {
            Utils.hideLoading();
        }
    },

    generateMockReportData(startDate, endDate) {
        const start = new Date(startDate);
        const end = new Date(endDate);
        const days = Math.ceil((end - start) / (1000 * 60 * 60 * 24));
        
        const revenue = [];
        const volume = [];
        
        for (let i = 0; i <= days; i++) {
            const date = new Date(start.getTime() + i * 24 * 60 * 60 * 1000);
            revenue.push({
                date: date.toISOString().split('T')[0],
                amount: Math.floor(Math.random() * 100000) + 50000
            });
            volume.push({
                date: date.toISOString().split('T')[0],
                count: Math.floor(Math.random() * 100) + 20
            });
        }
        
        return { revenue, volume };
    },

    createRevenueChart(data) {
        const ctx = document.getElementById('revenueChart');
        if (charts.revenue) charts.revenue.destroy();

        charts.revenue = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: data.map(d => Utils.formatDate(d.date)),
                datasets: [{
                    label: 'Revenus (XAF)',
                    data: data.map(d => d.amount),
                    backgroundColor: 'rgba(102, 126, 234, 0.8)',
                    borderColor: '#667eea',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    title: { display: true, text: 'Évolution des Revenus' }
                },
                scales: {
                    y: { beginAtZero: true }
                }
            }
        });
    },

    createVolumeChart(data) {
        const ctx = document.getElementById('volumeChart');
        if (charts.volume) charts.volume.destroy();

        charts.volume = new Chart(ctx, {
            type: 'line',
            data: {
                labels: data.map(d => Utils.formatDate(d.date)),
                datasets: [{
                    label: 'Nombre de Transactions',
                    data: data.map(d => d.count),
                    borderColor: '#28a745',
                    backgroundColor: 'rgba(40, 167, 69, 0.1)',
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    title: { display: true, text: 'Volume des Transactions' }
                },
                scales: {
                    y: { beginAtZero: true }
                }
            }
        });
    }
};

// ===============================
// Initialisation
// ===============================
document.addEventListener('DOMContentLoaded', () => {
    // Initialiser tous les modules
    Navigation.init();
    Dashboard.init();
    Transactions.init();
    Services.init();
    CallBox.init();
    Reports.init();
    
    console.log('MeRecharge Admin Dashboard initialized successfully');
});

// Nettoyage lors de la fermeture de la page
window.addEventListener('beforeunload', () => {
    // Nettoyer les intervalles
    Object.values(intervals).forEach(interval => clearInterval(interval));
    
    // Détruire les graphiques
    Object.values(charts).forEach(chart => chart && chart.destroy());
});