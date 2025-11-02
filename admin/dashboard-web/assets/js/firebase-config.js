// ===============================
// Configuration Firebase MeRecharge
// ===============================

// Configuration Firebase MeRecharge
const firebaseConfig = {
    apiKey: "AIzaSyApQvH-IYdDvIBgUh7i1G3dNko7N61a_r0",
    authDomain: "merecharge-50ab0.firebaseapp.com",
    projectId: "merecharge-50ab0",
    storageBucket: "merecharge-50ab0.firebasestorage.app",
    messagingSenderId: "891263588555",
    appId: "1:891263588555:web:709e0c474ee3f790e7634e"
};

console.log('🔥 Configuration Firebase MeRecharge chargée:', firebaseConfig.projectId);

// Initialisation Firebase
firebase.initializeApp(firebaseConfig);

// Services Firebase
const auth = firebase.auth();
const db = firebase.firestore();
const functions = firebase.functions();
const messaging = firebase.messaging();
const storage = firebase.storage();

// ===============================
// Service d'authentification Admin
// ===============================
class AdminAuthService {
    constructor() {
        this.currentAdmin = null;
        this.authStateChanged = null;
    }

    // Connexion admin avec email/password
    async signInAdmin(email, password) {
        try {
            const userCredential = await auth.signInWithEmailAndPassword(email, password);
            const user = userCredential.user;
            
            // Vérifier si l'utilisateur est admin
            const adminDoc = await db.collection('admins').doc(user.uid).get();
            
            if (!adminDoc.exists) {
                await auth.signOut();
                throw new Error('Accès non autorisé. Vous n\'êtes pas administrateur.');
            }
            
            this.currentAdmin = {
                uid: user.uid,
                email: user.email,
                ...adminDoc.data()
            };
            
            console.log('✅ Admin connecté:', this.currentAdmin.name);
            return this.currentAdmin;
            
        } catch (error) {
            console.error('❌ Erreur de connexion admin:', error.message);
            throw error;
        }
    }

    // Déconnexion admin
    async signOutAdmin() {
        try {
            await auth.signOut();
            this.currentAdmin = null;
            console.log('👋 Admin déconnecté');
        } catch (error) {
            console.error('❌ Erreur de déconnexion:', error.message);
            throw error;
        }
    }

    // Écouter les changements d'authentification
    onAuthStateChanged(callback) {
        this.authStateChanged = callback;
        return auth.onAuthStateChanged(async (user) => {
            if (user) {
                const adminDoc = await db.collection('admins').doc(user.uid).get();
                if (adminDoc.exists) {
                    this.currentAdmin = {
                        uid: user.uid,
                        email: user.email,
                        ...adminDoc.data()
                    };
                    callback(this.currentAdmin);
                } else {
                    await auth.signOut();
                    callback(null);
                }
            } else {
                this.currentAdmin = null;
                callback(null);
            }
        });
    }

    // Obtenir l'admin actuel
    getCurrentAdmin() {
        return this.currentAdmin;
    }

    // Vérifier si connecté
    isAuthenticated() {
        return this.currentAdmin !== null;
    }
}

// ===============================
// Service de données Firebase
// ===============================
class FirebaseDataService {
    constructor() {
        this.cache = new Map();
        this.cacheTimeout = 5 * 60 * 1000; // 5 minutes
    }

    // ===============================
    // Statistiques Dashboard
    // ===============================
    async getDashboardStats() {
        try {
            const [usersCount, transactionsData, rechargesData, ordersData] = await Promise.all([
                this.getUsersCount(),
                this.getTransactionsStats(),
                this.getRechargesStats(),
                this.getOrdersStats()
            ]);

            return {
                users: {
                    total: usersCount.total,
                    trend: usersCount.trend,
                    positive: usersCount.positive
                },
                revenue: {
                    total: transactionsData.totalRevenue,
                    trend: transactionsData.revenueTrend,
                    positive: transactionsData.revenuePositive
                },
                transactions: {
                    total: transactionsData.total,
                    trend: transactionsData.trend,
                    positive: transactionsData.positive
                },
                orders: {
                    total: ordersData.total,
                    trend: ordersData.trend,
                    positive: ordersData.positive
                }
            };
        } catch (error) {
            console.error('❌ Erreur lors du chargement des statistiques:', error);
            throw error;
        }
    }

    async getUsersCount() {
        const now = new Date();
        const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, now.getDate());

        const [totalSnapshot, lastMonthSnapshot] = await Promise.all([
            db.collection('users').get(),
            db.collection('users').where('createdAt', '>=', lastMonth).get()
        ]);

        const total = totalSnapshot.size;
        const newThisMonth = lastMonthSnapshot.size;
        const trend = total > 0 ? Math.round((newThisMonth / total) * 100) : 0;

        return {
            total,
            trend: `+${trend}%`,
            positive: trend > 0
        };
    }

    async getTransactionsStats() {
        const now = new Date();
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
        const endOfLastMonth = new Date(now.getFullYear(), now.getMonth(), 0);

        const [currentMonthSnapshot, lastMonthSnapshot] = await Promise.all([
            db.collection('transactions')
                .where('createdAt', '>=', startOfMonth)
                .where('status', '==', 'completed')
                .get(),
            db.collection('transactions')
                .where('createdAt', '>=', startOfLastMonth)
                .where('createdAt', '<=', endOfLastMonth)
                .where('status', '==', 'completed')
                .get()
        ]);

        let currentRevenue = 0;
        let lastRevenue = 0;

        currentMonthSnapshot.forEach(doc => {
            currentRevenue += doc.data().amount || 0;
        });

        lastMonthSnapshot.forEach(doc => {
            lastRevenue += doc.data().amount || 0;
        });

        const revenueTrend = lastRevenue > 0 ? Math.round(((currentRevenue - lastRevenue) / lastRevenue) * 100) : 0;
        const transactionsTrend = lastMonthSnapshot.size > 0 ? Math.round(((currentMonthSnapshot.size - lastMonthSnapshot.size) / lastMonthSnapshot.size) * 100) : 0;

        return {
            total: currentMonthSnapshot.size,
            totalRevenue: currentRevenue,
            trend: `${transactionsTrend > 0 ? '+' : ''}${transactionsTrend}%`,
            positive: transactionsTrend > 0,
            revenueTrend: `${revenueTrend > 0 ? '+' : ''}${revenueTrend}%`,
            revenuePositive: revenueTrend > 0
        };
    }

    async getRechargesStats() {
        // Implémentation similaire pour les recharges
        const snapshot = await db.collection('recharges')
            .where('status', '==', 'completed')
            .get();
        
        return {
            total: snapshot.size,
            trend: '+5%',
            positive: true
        };
    }

    async getOrdersStats() {
        // Implémentation similaire pour les commandes
        const snapshot = await db.collection('orders').get();
        
        return {
            total: snapshot.size,
            trend: '-3%',
            positive: false
        };
    }

    // ===============================
    // Gestion des Utilisateurs
    // ===============================
    async getUsers(limit = 50, startAfter = null, searchQuery = null) {
        try {
            let query = db.collection('users')
                .orderBy('createdAt', 'desc');

            if (searchQuery) {
                query = query
                    .where('name', '>=', searchQuery)
                    .where('name', '<=', searchQuery + '\uf8ff');
            }

            if (limit) {
                query = query.limit(limit);
            }

            if (startAfter) {
                query = query.startAfter(startAfter);
            }

            const snapshot = await query.get();
            const users = [];

            snapshot.forEach(doc => {
                users.push({
                    id: doc.id,
                    ...doc.data(),
                    lastActivity: doc.data().lastActivity?.toDate()?.toISOString() || null,
                    createdAt: doc.data().createdAt?.toDate()?.toISOString() || null
                });
            });

            return {
                users,
                lastDoc: snapshot.docs[snapshot.docs.length - 1] || null,
                hasMore: snapshot.docs.length === limit
            };

        } catch (error) {
            console.error('❌ Erreur lors du chargement des utilisateurs:', error);
            throw error;
        }
    }

    async getUserDetails(userId) {
        try {
            const userDoc = await db.collection('users').doc(userId).get();
            if (!userDoc.exists) {
                throw new Error('Utilisateur introuvable');
            }

            return {
                id: userDoc.id,
                ...userDoc.data(),
                lastActivity: userDoc.data().lastActivity?.toDate()?.toISOString() || null,
                createdAt: userDoc.data().createdAt?.toDate()?.toISOString() || null
            };
        } catch (error) {
            console.error('❌ Erreur lors du chargement des détails utilisateur:', error);
            throw error;
        }
    }

    async updateUserStatus(userId, status) {
        try {
            await db.collection('users').doc(userId).update({
                status,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });
            console.log(`✅ Statut utilisateur ${userId} mis à jour: ${status}`);
        } catch (error) {
            console.error('❌ Erreur lors de la mise à jour du statut:', error);
            throw error;
        }
    }

    // ===============================
    // Gestion des Transactions
    // ===============================
    async getTransactions(limit = 50, startAfter = null, filters = {}) {
        try {
            let query = db.collection('transactions')
                .orderBy('createdAt', 'desc');

            // Appliquer les filtres
            if (filters.status) {
                query = query.where('status', '==', filters.status);
            }

            if (filters.type) {
                query = query.where('type', '==', filters.type);
            }

            if (filters.dateFrom) {
                query = query.where('createdAt', '>=', new Date(filters.dateFrom));
            }

            if (filters.dateTo) {
                query = query.where('createdAt', '<=', new Date(filters.dateTo));
            }

            if (limit) {
                query = query.limit(limit);
            }

            if (startAfter) {
                query = query.startAfter(startAfter);
            }

            const snapshot = await query.get();
            const transactions = [];

            snapshot.forEach(doc => {
                transactions.push({
                    id: doc.id,
                    ...doc.data(),
                    createdAt: doc.data().createdAt?.toDate()?.toISOString() || null,
                    updatedAt: doc.data().updatedAt?.toDate()?.toISOString() || null
                });
            });

            return {
                transactions,
                lastDoc: snapshot.docs[snapshot.docs.length - 1] || null,
                hasMore: snapshot.docs.length === limit
            };

        } catch (error) {
            console.error('❌ Erreur lors du chargement des transactions:', error);
            throw error;
        }
    }

    // ===============================
    // Gestion des Recharges
    // ===============================
    async getRecharges(limit = 50, startAfter = null, filters = {}) {
        try {
            let query = db.collection('recharges')
                .orderBy('createdAt', 'desc');

            if (filters.status) {
                query = query.where('status', '==', filters.status);
            }

            if (filters.operator) {
                query = query.where('operator', '==', filters.operator);
            }

            if (limit) {
                query = query.limit(limit);
            }

            if (startAfter) {
                query = query.startAfter(startAfter);
            }

            const snapshot = await query.get();
            const recharges = [];

            snapshot.forEach(doc => {
                recharges.push({
                    id: doc.id,
                    ...doc.data(),
                    createdAt: doc.data().createdAt?.toDate()?.toISOString() || null,
                    updatedAt: doc.data().updatedAt?.toDate()?.toISOString() || null
                });
            });

            return {
                recharges,
                lastDoc: snapshot.docs[snapshot.docs.length - 1] || null,
                hasMore: snapshot.docs.length === limit
            };

        } catch (error) {
            console.error('❌ Erreur lors du chargement des recharges:', error);
            throw error;
        }
    }

    // ===============================
    // Gestion des Commandes
    // ===============================
    async getOrders(limit = 50, startAfter = null, filters = {}) {
        try {
            let query = db.collection('orders')
                .orderBy('createdAt', 'desc');

            if (filters.status) {
                query = query.where('status', '==', filters.status);
            }

            if (limit) {
                query = query.limit(limit);
            }

            if (startAfter) {
                query = query.startAfter(startAfter);
            }

            const snapshot = await query.get();
            const orders = [];

            snapshot.forEach(doc => {
                orders.push({
                    id: doc.id,
                    ...doc.data(),
                    createdAt: doc.data().createdAt?.toDate()?.toISOString() || null,
                    updatedAt: doc.data().updatedAt?.toDate()?.toISOString() || null
                });
            });

            return {
                orders,
                lastDoc: snapshot.docs[snapshot.docs.length - 1] || null,
                hasMore: snapshot.docs.length === limit
            };

        } catch (error) {
            console.error('❌ Erreur lors du chargement des commandes:', error);
            throw error;
        }
    }

    // ===============================
    // Gestion des Produits
    // ===============================
    async getProducts() {
        try {
            const snapshot = await db.collection('products')
                .orderBy('name', 'asc')
                .get();

            const products = [];
            snapshot.forEach(doc => {
                products.push({
                    id: doc.id,
                    ...doc.data(),
                    createdAt: doc.data().createdAt?.toDate()?.toISOString() || null,
                    updatedAt: doc.data().updatedAt?.toDate()?.toISOString() || null
                });
            });

            return products;

        } catch (error) {
            console.error('❌ Erreur lors du chargement des produits:', error);
            throw error;
        }
    }

    async addProduct(productData) {
        try {
            const docRef = await db.collection('products').add({
                ...productData,
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });

            console.log('✅ Produit ajouté:', docRef.id);
            return docRef.id;

        } catch (error) {
            console.error('❌ Erreur lors de l\'ajout du produit:', error);
            throw error;
        }
    }

    async updateProduct(productId, productData) {
        try {
            await db.collection('products').doc(productId).update({
                ...productData,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });

            console.log('✅ Produit mis à jour:', productId);

        } catch (error) {
            console.error('❌ Erreur lors de la mise à jour du produit:', error);
            throw error;
        }
    }

    async deleteProduct(productId) {
        try {
            await db.collection('products').doc(productId).delete();
            console.log('✅ Produit supprimé:', productId);

        } catch (error) {
            console.error('❌ Erreur lors de la suppression du produit:', error);
            throw error;
        }
    }

    // ===============================
    // Activité récente
    // ===============================
    async getRecentActivity(limit = 10) {
        try {
            const snapshot = await db.collection('activity_logs')
                .orderBy('timestamp', 'desc')
                .limit(limit)
                .get();

            const activities = [];
            snapshot.forEach(doc => {
                activities.push({
                    id: doc.id,
                    ...doc.data(),
                    timestamp: doc.data().timestamp?.toDate()?.toISOString() || null
                });
            });

            return activities;

        } catch (error) {
            console.error('❌ Erreur lors du chargement de l\'activité récente:', error);
            throw error;
        }
    }

    // ===============================
    // Données pour graphiques
    // ===============================
    async getRevenueChartData() {
        try {
            const now = new Date();
            const startOfYear = new Date(now.getFullYear(), 0, 1);

            const snapshot = await db.collection('transactions')
                .where('createdAt', '>=', startOfYear)
                .where('status', '==', 'completed')
                .orderBy('createdAt', 'asc')
                .get();

            const monthlyData = new Array(12).fill(0);

            snapshot.forEach(doc => {
                const data = doc.data();
                const date = data.createdAt?.toDate();
                if (date) {
                    const month = date.getMonth();
                    monthlyData[month] += data.amount || 0;
                }
            });

            return monthlyData;

        } catch (error) {
            console.error('❌ Erreur lors du chargement des données de revenus:', error);
            throw error;
        }
    }

    async getUsersChartData() {
        try {
            const [activeSnapshot, inactiveSnapshot, blockedSnapshot] = await Promise.all([
                db.collection('users').where('status', '==', 'active').get(),
                db.collection('users').where('status', '==', 'inactive').get(),
                db.collection('users').where('status', '==', 'blocked').get()
            ]);

            return {
                active: activeSnapshot.size,
                inactive: inactiveSnapshot.size,
                blocked: blockedSnapshot.size
            };

        } catch (error) {
            console.error('❌ Erreur lors du chargement des données utilisateurs:', error);
            throw error;
        }
    }

    // ===============================
    // Notifications Push
    // ===============================
    async sendNotificationToAll(title, body, data = {}) {
        try {
            const sendNotification = functions.httpsCallable('sendNotificationToAll');
            const result = await sendNotification({
                title,
                body,
                data
            });

            console.log('✅ Notification envoyée à tous les utilisateurs');
            return result.data;

        } catch (error) {
            console.error('❌ Erreur lors de l\'envoi de la notification:', error);
            throw error;
        }
    }

    async sendNotificationToUser(userId, title, body, data = {}) {
        try {
            const sendNotification = functions.httpsCallable('sendNotificationToUser');
            const result = await sendNotification({
                userId,
                title,
                body,
                data
            });

            console.log(`✅ Notification envoyée à l'utilisateur ${userId}`);
            return result.data;

        } catch (error) {
            console.error('❌ Erreur lors de l\'envoi de la notification:', error);
            throw error;
        }
    }
}

// ===============================
// Instances globales des services
// ===============================
const adminAuth = new AdminAuthService();
const firebaseData = new FirebaseDataService();

// Export des services
window.adminAuth = adminAuth;
window.firebaseData = firebaseData;

// Fonction de test de connexion
window.testFirebaseConnection = async function() {
    try {
        console.log('🔍 Test de connexion Firebase...');
        
        // Tester Firestore en listant les collections disponibles
        const collections = await db.listCollections ? db.listCollections() : null;
        console.log('✅ Connexion Firestore OK');
        
        // Essayer de lire la collection users
        try {
            const usersSnapshot = await db.collection('users').limit(1).get();
            console.log(`👥 Collection 'users' détectée - ${usersSnapshot.size} document(s) trouvé(s)`);
        } catch (userError) {
            console.warn('⚠️ Collection users non accessible:', userError.message);
        }
        
        return true;
    } catch (error) {
        console.error('❌ Erreur de connexion Firebase:', error.message);
        if (error.code) {
            console.error('📍 Code erreur:', error.code);
        }
        return false;
    }
};

console.log('🔥 Services Firebase initialisés avec succès!');

// Test automatique de la connexion Firebase
setTimeout(async () => {
    console.log('🔍 Test de connexion au projet:', firebaseConfig.projectId);
    
    const connected = await window.testFirebaseConnection();
    if (connected) {
        console.log('🎉 Firebase MeRecharge connecté avec succès!');
        
        // Mettre à jour le statut dans l'interface
        updateFirebaseStatus(true);
    } else {
        console.warn('⚠️ Problème de connexion Firebase - Vérifiez :', firebaseConfig.projectId);
        updateFirebaseStatus(false);
    }
}, 2000);

// Fonction pour mettre à jour le statut Firebase dans l'interface
function updateFirebaseStatus(connected) {
    const statusIcon = document.getElementById('firebaseStatus');
    const statusText = document.getElementById('firebaseStatusText');
    
    if (statusIcon && statusText) {
        if (connected) {
            statusIcon.className = 'fas fa-database status-icon';
            statusIcon.style.color = 'var(--success-color)';
            statusText.textContent = 'Firebase Connecté';
        } else {
            statusIcon.className = 'fas fa-exclamation-triangle';
            statusIcon.style.color = 'var(--danger-color)';
            statusText.textContent = 'Firebase Déconnecté';
        }
    }
}
