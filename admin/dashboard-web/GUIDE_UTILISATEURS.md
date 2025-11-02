# 👥 Guide Configuration - Onglet Utilisateurs

## 🎯 Objectif
Afficher les vrais utilisateurs de votre app MeRecharge dans le dashboard admin.

## 📋 Étapes de configuration

### 1. 🔥 Configuration Firebase

**Modifiez le fichier `assets/js/firebase-config.js`:**

Remplacez ces lignes (lignes 8-13) :
```javascript
apiKey: "votre-vraie-api-key-ici",
authDomain: "votre-projet.firebaseapp.com", 
projectId: "votre-project-id",
storageBucket: "votre-projet.appspot.com",
messagingSenderId: "votre-sender-id",
appId: "votre-app-id"
```

**Par votre vraie configuration Firebase :**

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet MeRecharge
3. Cliquez sur ⚙️ > **Paramètres du projet**
4. Dans **"Vos applications"** > **"SDK configuration"**
5. Copiez la configuration et remplacez dans le fichier

**Exemple :**
```javascript
const firebaseConfig = {
    apiKey: "AIzaSyC1234567890abcdef",
    authDomain: "merecharge-12345.firebaseapp.com",
    projectId: "merecharge-12345", 
    storageBucket: "merecharge-12345.appspot.com",
    messagingSenderId: "123456789",
    appId: "1:123456789:web:abcd1234efgh5678"
};
```

### 2. 📊 Structure Firestore requise

**Collection `users` dans Firestore :**

```javascript
// Document d'exemple dans la collection "users"
{
  id: "user123",
  name: "Jean Dupont", 
  email: "jean.dupont@example.com",
  phone: "+237698123456",
  status: "active", // active | inactive | blocked
  balance: 25000,
  photoURL: "https://...", // optionnel
  createdAt: timestamp,
  lastActivity: timestamp
}
```

**Statuts d'utilisateur supportés :**
- `active` : Utilisateur actif (badge vert)
- `inactive` : Utilisateur inactif (badge orange) 
- `blocked` : Utilisateur bloqué (badge rouge)

### 3. 🔐 Règles de sécurité Firestore

**Dans Firebase Console > Firestore > Rules :**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permettre la lecture des utilisateurs pour les admins authentifiés
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }
    
    // Collection admins (pour l'authentification admin)
    match /admins/{adminId} {
      allow read: if request.auth != null && request.auth.uid == adminId;
    }
  }
}
```

### 4. 👤 Créer un compte admin

**Dans Firestore, créez la collection `admins` :**

```javascript
// Document dans la collection "admins" 
{
  name: "Admin Principal",
  email: "admin@merecharge.com",
  role: "super_admin", 
  permissions: ["users", "transactions", "reports"],
  createdAt: new Date(),
  lastLogin: new Date()
}
```

**L'ID du document doit être l'UID Firebase Auth de l'admin.**

### 5. 🚀 Test de fonctionnement

1. **Lancez le serveur local :**
```bash
python3 -m http.server 8000
```

2. **Ouvrez http://localhost:8000**

3. **Vérifiez la console (F12) :**
- ✅ `Firebase connecté avec succès!`
- ✅ `X utilisateurs chargés depuis Firebase`

4. **Cliquez sur l'onglet "Utilisateurs" :**
- Vous devriez voir vos vrais utilisateurs
- Avatars, noms, emails, téléphones
- Boutons d'actions fonctionnels

### 6. 🎨 Fonctionnalités disponibles

**Dans l'onglet Utilisateurs :**
- 📋 **Liste complète** des utilisateurs
- 🔍 **Recherche** par nom, email, téléphone  
- 👁️ **Voir détails** (modal avec toutes les infos)
- ✏️ **Modifier** (ouvre un formulaire d'édition)
- 🚫 **Bloquer/Débloquer** utilisateur
- 💾 **Export** de la liste en CSV
- 🎨 **Avatars** automatiques avec initiales
- 🏷️ **Badges de statut** colorés

### 7. 🐛 Dépannage

**Si les utilisateurs ne s'affichent pas :**

1. **Vérifiez la console (F12) :**
   - Erreurs Firebase en rouge ?
   - Message "Fallback vers les données de test" ?

2. **Configuration Firebase :**
   - ✅ Vraies clés copiées ?
   - ✅ Projet Firebase actif ?
   - ✅ Facturation activée ?

3. **Collection Firestore :**
   - ✅ Collection `users` existe ?
   - ✅ Documents avec la bonne structure ?
   - ✅ Règles de sécurité correctes ?

4. **Test manuel :**
```javascript
// Dans la console du navigateur (F12)
await window.testFirebaseConnection()
await window.firebaseData.getUsers(10)
```

### 8. 📝 Ajout manuel d'utilisateurs test

**Si vous n'avez pas encore d'utilisateurs, créez-en manuellement :**

1. Firebase Console > Firestore
2. Collection `users` > Ajouter un document
3. Utilisez cette structure :

```javascript
{
  name: "Utilisateur Test",
  email: "test@example.com", 
  phone: "+237698123456",
  status: "active",
  balance: 10000,
  createdAt: new Date(),
  lastActivity: new Date()
}
```

---

## 🎉 Résultat attendu

Une fois configuré, l'onglet **"Utilisateurs"** affichera :
- ✅ Vos vrais utilisateurs MeRecharge
- ✅ Interface moderne et responsive  
- ✅ Actions complètes (voir, modifier, bloquer)
- ✅ Recherche et filtrage
- ✅ Export des données

**🚀 Prêt à tester ? Lancez le serveur et naviguez vers l'onglet Utilisateurs !**