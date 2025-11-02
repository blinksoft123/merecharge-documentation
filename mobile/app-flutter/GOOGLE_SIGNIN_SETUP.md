# 🔐 Configuration Google Sign-In

## Guide complet pour activer la connexion Google

### ✅ Étape 1: Activer Google Sign-In dans Firebase Console

1. **Ouvrez Firebase Console**
   ```
   https://console.firebase.google.com/project/merecharge-50ab0
   ```

2. **Allez dans Authentication**
   - Dans le menu de gauche, cliquez sur **"Build"** → **"Authentication"**
   - Cliquez sur l'onglet **"Sign-in method"**

3. **Activez Google comme provider**
   - Trouvez **"Google"** dans la liste des providers
   - Cliquez dessus
   - Activez le switch **"Enable"**
   - Renseignez les informations :
     - **Project public-facing name**: MeRecharge
     - **Project support email**: Votre email (investbligroup@gmail.com)
   - Cliquez sur **"Save"**

### ✅ Étape 2: Obtenir le SHA-1 de votre clé de debug Android

Le SHA-1 est nécessaire pour que Firebase reconnaisse votre application.

#### Sur macOS/Linux:

```bash
# Méthode 1: Avec keytool (Recommandé)
cd ~/.android
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Méthode 2: Avec Gradle (depuis votre projet)
cd "/Users/serge/Desktop/merecharge flutter/android"
./gradlew signingReport
```

#### Ce que vous devez chercher:

Dans la sortie, trouvez la ligne qui commence par **"SHA1:"** ou **"SHA-1:"**

Exemple:
```
SHA1: A1:B2:C3:D4:E5:F6:G7:H8:I9:J0:K1:L2:M3:N4:O5:P6:Q7:R8:S9:T0
```

**Copiez ce code SHA-1 !**

### ✅ Étape 3: Ajouter le SHA-1 dans Firebase

1. **Retournez dans Firebase Console**
   ```
   https://console.firebase.google.com/project/merecharge-50ab0/settings/general
   ```

2. **Allez dans Project Settings**
   - Cliquez sur l'icône ⚙️ (engrenage) en haut à gauche
   - Cliquez sur **"Project Settings"**

3. **Trouvez votre application Android**
   - Faites défiler jusqu'à la section **"Your apps"**
   - Trouvez l'app Android: `com.meerecharge.blinksoft`

4. **Ajoutez le SHA-1**
   - Cliquez sur votre app Android
   - Faites défiler jusqu'à **"SHA certificate fingerprints"**
   - Cliquez sur **"Add fingerprint"**
   - Collez votre SHA-1
   - Cliquez sur **"Save"**

### ✅ Étape 4: Télécharger le nouveau google-services.json

Après avoir ajouté le SHA-1, Firebase génère un nouveau `google-services.json`.

1. **Téléchargez le fichier mis à jour**
   - Toujours dans Project Settings
   - Trouvez votre app Android
   - Cliquez sur le bouton **"google-services.json"** pour télécharger

2. **Remplacez l'ancien fichier**
   ```bash
   # Supprimez l'ancien
   rm "/Users/serge/Desktop/merecharge flutter/android/app/google-services.json"
   
   # Copiez le nouveau (depuis vos Téléchargements)
   cp ~/Downloads/google-services.json "/Users/serge/Desktop/merecharge flutter/android/app/"
   ```

### ✅ Étape 5: (Optionnel) Obtenir le SHA-1 de release

Pour la version de production, vous aurez besoin du SHA-1 de votre clé de signature release.

#### Si vous utilisez une keystore personnalisée:

```bash
keytool -list -v -keystore /path/to/your/release.keystore -alias your_alias
```

#### Si vous uploadez sur Google Play:

Google Play génère automatiquement une clé. Vous pouvez trouver le SHA-1 dans:
- Google Play Console → Votre app → Release → App signing

**Ajoutez ce SHA-1 également dans Firebase** (même processus qu'étape 3).

### ✅ Étape 6: Vérifier la configuration Android

Vérifiez que votre `android/app/build.gradle.kts` contient bien:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ✅ Important!
}

android {
    namespace = "com.meerecharge.blinksoft"
    // ...
}
```

✅ **Déjà configuré dans votre projet !**

### ✅ Étape 7: Recompiler et tester

1. **Nettoyez le build**
   ```bash
   cd "/Users/serge/Desktop/merecharge flutter"
   flutter clean
   flutter pub get
   ```

2. **Recompilez et installez**
   ```bash
   flutter run -d 11211153B7017870
   ```

3. **Testez Google Sign-In**
   - Ouvrez l'app
   - Cliquez sur "Se Connecter"
   - Cliquez sur "Continuer avec Google"
   - Sélectionnez votre compte Google
   - ✅ Ça devrait fonctionner !

## 🔍 Script automatique pour obtenir SHA-1

Créez ce script pour faciliter l'obtention du SHA-1:

```bash
#!/bin/bash
# get_sha1.sh

echo "🔐 Obtention du SHA-1 Debug..."
echo ""

# SHA-1 Debug
echo "📱 SHA-1 de la clé de DEBUG:"
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android 2>/dev/null | grep "SHA1:"

echo ""
echo "📋 Copiez le SHA-1 ci-dessus et ajoutez-le dans Firebase Console"
echo "   → https://console.firebase.google.com/project/merecharge-50ab0/settings/general"
```

**Utilisation:**
```bash
chmod +x get_sha1.sh
./get_sha1.sh
```

## 🚨 Résolution des problèmes courants

### Problème 1: "Google Sign-In failed" ou "Sign in cancelled"

**Causes possibles:**
- SHA-1 non configuré dans Firebase
- google-services.json pas à jour
- Email de support non configuré dans Firebase Auth

**Solution:**
1. Vérifiez que le SHA-1 est bien ajouté dans Firebase
2. Re-téléchargez google-services.json
3. Recompilez complètement l'app (`flutter clean` puis `flutter run`)

### Problème 2: "PlatformException (sign_in_failed)"

**Cause:** SHA-1 ne correspond pas ou n'est pas configuré

**Solution:**
```bash
# Obtenez le SHA-1 avec cette commande
cd "/Users/serge/Desktop/merecharge flutter/android"
./gradlew signingReport | grep SHA1

# Ajoutez-le dans Firebase Console
```

### Problème 3: "The package name com.meerecharge.blinksoft is not registered"

**Cause:** Le package name dans Firebase ne correspond pas

**Solution:**
- Vérifiez dans Firebase Console que l'app Android a bien le package: `com.meerecharge.blinksoft`
- Vérifiez dans `android/app/build.gradle.kts` que `applicationId = "com.meerecharge.blinksoft"`

### Problème 4: "clientId not registered"

**Cause:** google-services.json pas à jour après ajout du SHA-1

**Solution:**
1. Re-téléchargez google-services.json depuis Firebase
2. Remplacez le fichier dans `android/app/`
3. Recompilez

## ✅ Checklist finale

Avant de tester Google Sign-In, vérifiez:

- [ ] Google est activé dans Firebase Authentication
- [ ] Email de support est configuré dans Firebase Auth
- [ ] SHA-1 obtenu avec `keytool` ou `gradlew signingReport`
- [ ] SHA-1 ajouté dans Firebase Console (Project Settings)
- [ ] google-services.json téléchargé et remplacé
- [ ] `flutter clean` exécuté
- [ ] `flutter pub get` exécuté
- [ ] App recompilée et installée
- [ ] Appareil a Google Play Services installé

## 📱 Test sur appareil réel vs émulateur

### Appareil réel (Votre itel A665L)
✅ **Recommandé** - Google Play Services installé par défaut

### Émulateur Android
⚠️ **Nécessite** un émulateur avec Google Play Services
- Utilisez une image système avec "Google APIs" ou "Google Play"
- Pas les images "vanilla" Android

## 🎯 Résumé rapide (TL;DR)

```bash
# 1. Obtenez le SHA-1
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1

# 2. Allez dans Firebase Console
open "https://console.firebase.google.com/project/merecharge-50ab0/settings/general"

# 3. Ajoutez le SHA-1 dans "SHA certificate fingerprints"

# 4. Téléchargez le nouveau google-services.json

# 5. Remplacez le fichier
cp ~/Downloads/google-services.json "/Users/serge/Desktop/merecharge flutter/android/app/"

# 6. Recompilez
cd "/Users/serge/Desktop/merecharge flutter"
flutter clean
flutter pub get
flutter run -d 11211153B7017870

# 7. Testez dans l'app!
```

## 📞 Support

Si vous rencontrez des problèmes:
1. Vérifiez les logs: `adb logcat | grep -i google`
2. Consultez la console Firebase pour voir les erreurs d'authentification
3. Assurez-vous que votre appareil a une connexion internet

---

**Documentation officielle:**
- Firebase: https://firebase.google.com/docs/auth/android/google-signin
- Google Sign-In: https://pub.dev/packages/google_sign_in

**Dernière mise à jour:** 2025-10-13
