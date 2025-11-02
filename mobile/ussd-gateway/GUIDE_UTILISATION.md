# 📱 GUIDE D'UTILISATION - MeRecharge USSD Gateway

## 🎯 VUE D'ENSEMBLE

**MeRecharge USSD Gateway** (aussi appelé **CallBox**) est une application Android qui automatise l'exécution de codes USSD pour le système MeRecharge. Elle fonctionne comme un **pont automatisé** entre votre backend MeRecharge et les opérateurs télécom (Orange, MTN, Camtel).

---

## 🔄 FLUX D'UTILISATION COMPLET

### **Schéma du Système**

```
┌──────────────────┐          ┌──────────────────┐          ┌──────────────────┐
│                  │          │                  │          │                  │
│   MeRecharge     │  ──────► │   CallBox App    │  ──────► │    Opérateurs    │
│   Backend        │          │   (Android)      │          │  Orange/MTN/etc  │
│  (Node.js API)   │          │                  │          │                  │
│                  │  ◄────── │                  │  ◄────── │                  │
└──────────────────┘          └──────────────────┘          └──────────────────┘
     Étape 1                       Étape 2-4                     Étape 5
  Envoie transactions          Traite via USSD              Exécute & répond
```

---

## 📋 SCÉNARIO D'UTILISATION DÉTAILLÉ

### **Cas Pratique : Recharge Orange Money**

Un client demande une recharge de **5,000 FCFA** sur Orange Money.

#### **ÉTAPE 1 : Backend MeRecharge créé la transaction**

Votre backend reçoit la demande du client et prépare la transaction :

```json
{
  "id": "TXN_20251010_001234",
  "type": "topup",
  "operator": "orange",
  "fromPhone": "677001122",
  "toPhone": "677334455",
  "amount": 5000,
  "fees": 150,
  "ussdCode": "#130*1*677334455*5000*1234#",
  "createdAt": "2025-10-10T07:00:00Z"
}
```

#### **ÉTAPE 2 : CallBox récupère la transaction**

L'application CallBox **interroge automatiquement** le backend toutes les 2 secondes :

```
GET http://localhost:4000/api/call-box/transactions/pending
```

**Réponse du backend :**
```json
{
  "transactions": [
    {
      "id": "TXN_20251010_001234",
      "type": "topup",
      "operator": "orange",
      "ussdCode": "#130*1*677334455*5000*1234#",
      ...
    }
  ]
}
```

#### **ÉTAPE 3 : CallBox ajoute à la file d'attente**

```
📥 Transaction reçue : TXN_20251010_001234
📊 Statut : PENDING
⏳ En attente de traitement...
```

L'application affiche dans le Dashboard :
- **En attente** : 1 transaction
- **En cours** : 0
- **Réussies** : 0

#### **ÉTAPE 4 : CallBox traite la transaction**

Le système vérifie qu'il peut traiter la transaction (max 5 simultanées) et lance l'exécution :

```
🔄 Traitement de : TXN_20251010_001234
📱 Opérateur : Orange
💰 Montant : 5,000 FCFA
📞 Code USSD : #130*1*677334455*5000*1234#
```

**Sur le téléphone Android :**
1. L'application compose automatiquement le code USSD
2. Attend la réponse de l'opérateur (3-15 secondes)
3. Capture la réponse USSD

#### **ÉTAPE 5 : Réponse de l'opérateur**

**CAS DE SUCCÈS (85% du temps) :**
```
✅ Transfert Orange Money réussi
   Nouveau solde: 45,250 FCFA
   Frais: 150 FCFA
   Réf: OM241010123456
```

**CAS D'ÉCHEC (15% du temps) :**
```
❌ Solde insuffisant pour effectuer cette transaction
```

#### **ÉTAPE 6 : CallBox notifie le backend**

L'application envoie le résultat à MeRecharge :

```
PUT http://localhost:4000/api/call-box/transactions/TXN_20251010_001234/status

Payload:
{
  "status": "success",
  "callBoxResponse": "Transfert Orange Money réussi. Réf: OM241010123456",
  "errorMessage": null,
  "updatedAt": "2025-10-10T07:00:15Z"
}
```

#### **ÉTAPE 7 : Backend met à jour le client**

Votre backend MeRecharge reçoit le statut et peut :
- ✅ Confirmer au client que la recharge est effectuée
- 💳 Débiter le compte du client
- 📧 Envoyer un email/SMS de confirmation
- 📊 Mettre à jour les statistiques

---

## 🎨 INTERFACE UTILISATEUR DE L'APPLICATION

L'application CallBox a **3 écrans principaux** :

### **1. 📊 DASHBOARD (Écran principal)**

```
╔════════════════════════════════════════════════╗
║  🏠 MeRecharge Call Box           [v1.0.0]    ║
╠════════════════════════════════════════════════╣
║                                                ║
║  📈 STATISTIQUES AUJOURD'HUI                   ║
║  ┌────────────┬────────────┬────────────┐     ║
║  │ En attente │  En cours  │  Réussies  │     ║
║  │     3      │      2     │     45     │     ║
║  └────────────┴────────────┴────────────┘     ║
║  ┌────────────┐                               ║
║  │  Échecs    │                               ║
║  │     2      │                               ║
║  └────────────┘                               ║
║                                                ║
║  🎯 OPÉRATEURS                                 ║
║  ┌──────────────────────────────────┐         ║
║  │ 🟠 Orange    ✅ Actif    23 TXN  │         ║
║  │ 🟡 MTN       ✅ Actif    18 TXN  │         ║
║  │ 🔵 Camtel    ✅ Actif     4 TXN  │         ║
║  └──────────────────────────────────┘         ║
║                                                ║
║  ⚡ DERNIÈRES TRANSACTIONS                     ║
║  • TXN_001234 - Orange - 5,000 F - ✅         ║
║  • TXN_001233 - MTN    - 2,000 F - ✅         ║
║  • TXN_001232 - Orange - 10,000 F - ⏳        ║
║                                                ║
╠════════════════════════════════════════════════╣
║  [Dashboard]  [Transactions]  [Paramètres]    ║
╚════════════════════════════════════════════════╝
```

**Ce que vous voyez en temps réel :**
- Nombre de transactions en attente
- Transactions en cours de traitement
- Taux de réussite
- Performance par opérateur
- Activité récente

### **2. 📜 TRANSACTIONS (Historique détaillé)**

```
╔════════════════════════════════════════════════╗
║  📜 Transactions                               ║
╠════════════════════════════════════════════════╣
║                                                ║
║  🔍 [Rechercher...]    [Filtres ▾]            ║
║                                                ║
║  ┌────────────────────────────────────────┐   ║
║  │ TXN_001234              10:15:23       │   ║
║  │ Orange • Recharge • 5,000 FCFA         │   ║
║  │ 677334455 ← 677001122                  │   ║
║  │ ✅ Succès (12s)                         │   ║
║  │ Réf: OM241010123456                    │   ║
║  └────────────────────────────────────────┘   ║
║                                                ║
║  ┌────────────────────────────────────────┐   ║
║  │ TXN_001233              10:14:45       │   ║
║  │ MTN • Transfert • 2,000 FCFA           │   ║
║  │ 650112233 ← 650998877                  │   ║
║  │ ✅ Succès (8s)                          │   ║
║  │ Réf: MTNMOMO789456                     │   ║
║  └────────────────────────────────────────┘   ║
║                                                ║
║  ┌────────────────────────────────────────┐   ║
║  │ TXN_001232              10:13:12       │   ║
║  │ Orange • Recharge • 10,000 FCFA        │   ║
║  │ ⏳ En cours... (5s)                     │   ║
║  └────────────────────────────────────────┘   ║
║                                                ║
║  ┌────────────────────────────────────────┐   ║
║  │ TXN_001231              10:12:01       │   ║
║  │ MTN • Data Bundle • 3,000 FCFA         │   ║
║  │ ❌ Échec (Solde insuffisant)            │   ║
║  │ [🔄 Réessayer]                          │   ║
║  └────────────────────────────────────────┘   ║
║                                                ║
╠════════════════════════════════════════════════╣
║  [Dashboard]  [Transactions]  [Paramètres]    ║
╚════════════════════════════════════════════════╝
```

**Informations détaillées :**
- ID de la transaction
- Heure exacte
- Opérateur et type
- Montant et destinataire
- Statut avec temps d'exécution
- Référence opérateur
- Bouton pour réessayer les échecs

### **3. ⚙️ PARAMÈTRES (Configuration)**

```
╔════════════════════════════════════════════════╗
║  ⚙️ Paramètres                                 ║
╠════════════════════════════════════════════════╣
║                                                ║
║  🔌 CONNEXION BACKEND                          ║
║  ┌────────────────────────────────────────┐   ║
║  │ URL API: http://localhost:4000/api     │   ║
║  │ ● Connecté                             │   ║
║  │ [Tester la connexion]                  │   ║
║  └────────────────────────────────────────┘   ║
║                                                ║
║  📱 CONFIGURATION CALLBOX                      ║
║  ┌────────────────────────────────────────┐   ║
║  │ ID CallBox: CALLBOX_001                │   ║
║  │ Version: 1.0.0                         │   ║
║  │ Port serveur: 8080                     │   ║
║  └────────────────────────────────────────┘   ║
║                                                ║
║  ⚡ PERFORMANCE                                 ║
║  ┌────────────────────────────────────────┐   ║
║  │ Transactions simultanées: [5 ▾]        │   ║
║  │ Timeout USSD: [30s ▾]                  │   ║
║  │ Tentatives max: [3 ▾]                  │   ║
║  └────────────────────────────────────────┘   ║
║                                                ║
║  🔔 NOTIFICATIONS                               ║
║  ┌────────────────────────────────────────┐   ║
║  │ ☑ Activer notifications                │   ║
║  │ ☑ Sons                                  │   ║
║  │ ☐ Vibrations                            │   ║
║  └────────────────────────────────────────┘   ║
║                                                ║
║  🗑️ MAINTENANCE                                ║
║  ┌────────────────────────────────────────┐   ║
║  │ [Vider la file d'attente]              │   ║
║  │ [Effacer l'historique]                 │   ║
║  │ [Réinitialiser l'application]          │   ║
║  └────────────────────────────────────────┘   ║
║                                                ║
╠════════════════════════════════════════════════╣
║  [Dashboard]  [Transactions]  [Paramètres]    ║
╚════════════════════════════════════════════════╝
```

---

## 🚀 DÉMARRAGE ET UTILISATION QUOTIDIENNE

### **Installation initiale**

```bash
# 1. Installer l'app sur un téléphone Android
flutter build apk --release
flutter install

# 2. Au premier lancement, l'app :
✅ Démarre le serveur HTTP sur port 8080
✅ S'enregistre auprès du backend MeRecharge
✅ Commence à écouter les nouvelles transactions
```

### **Utilisation quotidienne**

**1. MATIN : Démarrage**
```
📱 Ouvrir l'application CallBox
✅ Vérifier la connexion backend (indicateur vert)
✅ S'assurer que le téléphone a du crédit
✅ Vérifier que toutes les SIMs sont actives
```

**2. JOURNÉE : Surveillance**
```
👀 L'application fonctionne AUTOMATIQUEMENT
📊 Consulter le Dashboard régulièrement
📈 Vérifier les statistiques en temps réel
⚠️ Réagir aux notifications d'échec si nécessaire
```

**3. INTERVENTIONS MANUELLES (si nécessaire)**
```
🔄 Réessayer une transaction échouée :
   1. Aller dans "Transactions"
   2. Trouver la transaction échouée
   3. Appuyer sur "Réessayer"

❌ Annuler une transaction :
   1. Glisser vers la gauche sur la transaction
   2. Appuyer sur "Annuler"

🔍 Consulter les détails :
   1. Appuyer sur une transaction
   2. Voir tous les détails (USSD, réponse, timing)
```

**4. SOIR : Vérification**
```
📊 Consulter les statistiques du jour
✅ Vérifier que la file d'attente est vide
💾 L'historique est sauvegardé automatiquement
```

---

## 🔧 GESTION DES SITUATIONS PARTICULIÈRES

### **📶 Problème de réseau opérateur**

**Symptôme :** Plusieurs échecs pour un opérateur spécifique

**Solution :**
```
1. Vérifier le crédit de la SIM
2. Redémarrer le téléphone si nécessaire
3. L'app va automatiquement réessayer 3 fois
4. Consulter les erreurs dans "Transactions"
```

### **⚠️ File d'attente qui grandit**

**Symptôme :** Nombre de transactions "En attente" augmente

**Causes possibles :**
- Trop de transactions simultanées (augmenter la limite dans Paramètres)
- Délais USSD longs (normal, attendre)
- Problème réseau (vérifier connexion)

**Solution :**
```
Aller dans Paramètres
Augmenter "Transactions simultanées" de 5 à 8
```

### **❌ Échecs répétés**

**L'application gère automatiquement :**
- ✅ 1ère tentative échoue → Réessaie après 10 secondes
- ✅ 2ème tentative échoue → Réessaie après 10 secondes
- ✅ 3ème tentative échoue → Marque comme ÉCHEC définitif
- 📧 Le backend est notifié à chaque étape

**Actions manuelles :**
```
1. Consulter le message d'erreur
2. Si "Solde insuffisant" → Recharger la SIM
3. Si "Service indisponible" → Attendre et réessayer plus tard
4. Utiliser le bouton "Réessayer" dans l'interface
```

### **🔄 Déconnexion backend**

**Symptôme :** Indicateur rouge dans Dashboard

**Comportement :**
```
🟢 Mode normal : Récupère les transactions toutes les 2s
🔴 Mode déconnecté : 
   - Continue à traiter la file existante
   - Stocke les résultats localement
   - Réessaie la connexion toutes les 30s
   - Synchronise dès que la connexion revient
```

---

## 📊 MÉTRIQUES ET MONITORING

### **Statistiques disponibles**

L'application génère ces statistiques automatiquement :

```json
{
  "callBoxId": "CALLBOX_001",
  "period": "2025-10-10",
  "metrics": {
    "totalTransactions": 150,
    "successRate": 87.3,
    "averageProcessingTime": "8.5s",
    "byOperator": {
      "orange": {
        "total": 68,
        "success": 61,
        "failed": 7,
        "successRate": 89.7
      },
      "mtn": {
        "total": 72,
        "success": 60,
        "failed": 12,
        "successRate": 83.3
      },
      "camtel": {
        "total": 10,
        "success": 10,
        "failed": 0,
        "successRate": 100
      }
    },
    "byType": {
      "topup": 95,
      "transfer": 40,
      "data_bundle": 15
    },
    "peakHours": ["10:00", "14:00", "18:00"]
  }
}
```

**Ces stats sont envoyées au backend toutes les heures.**

---

## 💡 BONNES PRATIQUES

### **✅ À FAIRE**

1. **Garder l'application ouverte en permanence**
   - L'app doit tourner en avant-plan pour exécuter les USSD
   - Désactiver la mise en veille automatique du téléphone

2. **Maintenir un crédit suffisant sur les SIMs**
   - Vérifier régulièrement le solde
   - Recharger avant qu'il soit trop bas

3. **Surveiller le Dashboard quotidiennement**
   - Vérifier le taux de réussite
   - Identifier les problèmes récurrents

4. **Garder le téléphone chargé**
   - Brancher en permanence si possible
   - Utiliser un support/stand pour le téléphone

5. **Tester la connexion backend régulièrement**
   - Utiliser le bouton "Tester connexion"
   - S'assurer que l'indicateur est vert

### **❌ À ÉVITER**

1. **Ne PAS fermer l'application pendant la journée**
   - Risque de perdre des transactions en cours

2. **Ne PAS utiliser le téléphone pour des appels**
   - Dédie ce téléphone uniquement au CallBox

3. **Ne PAS modifier les codes USSD manuellement**
   - Ils sont générés automatiquement par le backend

4. **Ne PAS vider la file d'attente sans raison**
   - Risque de perdre des transactions clients

5. **Ne PAS ignorer les erreurs répétées**
   - Elles indiquent souvent un problème à résoudre

---

## 🎯 RÉSUMÉ : L'APPLICATION EN 5 POINTS

1. **📥 RÉCEPTION** : Récupère automatiquement les transactions depuis MeRecharge
2. **⏳ FILE D'ATTENTE** : Organise et priorise les transactions
3. **📱 EXÉCUTION** : Exécute les codes USSD sur le téléphone Android
4. **📊 MONITORING** : Affiche tout en temps réel dans une interface claire
5. **✅ NOTIFICATION** : Renvoie les résultats au backend MeRecharge

**L'opérateur humain n'a qu'à surveiller, l'application fait TOUT automatiquement !**

---

## 🆘 SUPPORT ET DÉPANNAGE

### Contact en cas de problème :
- 📧 Email technique: support@merecharge.com
- 📱 Téléphone: +237 6XX XXX XXX
- 📖 Documentation: http://localhost:4000/docs/callbox

### Logs de débogage :
```bash
# Consulter les logs en temps réel
flutter logs

# Exporter les logs pour support
Paramètres → Maintenance → Exporter les logs
```

---

**Version du document : 1.0**  
**Dernière mise à jour : 10 octobre 2025**
