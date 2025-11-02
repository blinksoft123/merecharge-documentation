import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  
  // Initialiser Google Sign-In
  Future<void> _initializeGoogleSignIn() async {
    await _googleSignIn.initialize(
      // Les scopes sont maintenant gérés différemment dans v7.2.0
    );
  }

  // Stream pour écouter les changements d'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Inscription avec email et mot de passe
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  }) async {
    try {
      // Créer l'utilisateur dans Firebase Auth
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;
      if (user == null) {
        return {
          'success': false,
          'error': 'Échec de la création du compte',
        };
      }

      // Mettre à jour le profil avec le nom
      await user.updateDisplayName(name);

      // Créer le document utilisateur dans Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'name': name,
        'phoneNumber': phoneNumber,
        'balance': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isVerified': false,
        'role': 'user', // user, admin
      });

      // Envoyer l'email de vérification
      await user.sendEmailVerification();

      return {
        'success': true,
        'user': user,
        'message': 'Compte créé avec succès. Veuillez vérifier votre email.',
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Le mot de passe est trop faible';
          break;
        case 'email-already-in-use':
          errorMessage = 'Cet email est déjà utilisé';
          break;
        case 'invalid-email':
          errorMessage = 'Email invalide';
          break;
        default:
          errorMessage = 'Erreur: ${e.message}';
      }
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur inattendue: $e',
      };
    }
  }

  // Connexion avec email et mot de passe
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;
      if (user == null) {
        return {
          'success': false,
          'error': 'Échec de la connexion',
        };
      }

      return {
        'success': true,
        'user': user,
        'message': 'Connexion réussie',
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Aucun utilisateur trouvé avec cet email';
          break;
        case 'wrong-password':
          errorMessage = 'Mot de passe incorrect';
          break;
        case 'invalid-email':
          errorMessage = 'Email invalide';
          break;
        case 'user-disabled':
          errorMessage = 'Ce compte a été désactivé';
          break;
        default:
          errorMessage = 'Erreur: ${e.message}';
      }
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur inattendue: $e',
      };
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Réinitialisation du mot de passe
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Email de réinitialisation envoyé',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Erreur lors de la réinitialisation',
      };
    }
  }

  // Obtenir les données utilisateur depuis Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print('Erreur lors de la récupération des données: $e');
      return null;
    }
  }

  // Mettre à jour les données utilisateur
  Future<bool> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(uid).update(data);
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour: $e');
      return false;
    }
  }

  // Vérifier si l'email est vérifié
  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Renvoyer l'email de vérification
  Future<Map<String, dynamic>> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return {
        'success': true,
        'message': 'Email de vérification renvoyé',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: $e',
      };
    }
  }

  // Changer le mot de passe
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return {
          'success': false,
          'error': 'Utilisateur non connecté',
        };
      }

      // Ré-authentifier l'utilisateur
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Changer le mot de passe
      await user.updatePassword(newPassword);

      return {
        'success': true,
        'message': 'Mot de passe changé avec succès',
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Mot de passe actuel incorrect';
          break;
        case 'weak-password':
          errorMessage = 'Le nouveau mot de passe est trop faible';
          break;
        default:
          errorMessage = 'Erreur: ${e.message}';
      }
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur inattendue: $e',
      };
    }
  }

  // Connexion avec Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Initialiser Google Sign-In si nécessaire
      await _initializeGoogleSignIn();
      
      // Démarrer le processus de connexion Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );
      
      if (googleUser == null) {
        return {
          'success': false,
          'error': 'Connexion Google annulée',
        };
      }

      // Obtenir les détails d'authentification
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Obtenir l'access token via le client d'autorisation
      final GoogleSignInClientAuthorization? authorizationTokens = 
          await googleUser.authorizationClient.authorizationForScopes(['email', 'profile']);

      // Créer les credentials Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: authorizationTokens?.accessToken,
        idToken: googleAuth.idToken,
      );

      // Se connecter à Firebase avec les credentials Google
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        return {
          'success': false,
          'error': 'Échec de la connexion Google',
        };
      }

      // Créer ou mettre à jour le document utilisateur dans Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        // Créer un nouveau document pour les nouveaux utilisateurs
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ?? 'Utilisateur',
          'phoneNumber': user.phoneNumber ?? '',
          'photoURL': user.photoURL,
          'balance': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isVerified': user.emailVerified,
          'role': 'user',
          'provider': 'google',
        });
      } else {
        // Mettre à jour les infos existantes
        await _firestore.collection('users').doc(user.uid).update({
          'updatedAt': FieldValue.serverTimestamp(),
          'photoURL': user.photoURL,
        });
      }

      return {
        'success': true,
        'user': user,
        'message': 'Connexion Google réussie',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur lors de la connexion Google: $e',
      };
    }
  }

  // Authentification par numéro de téléphone - Étape 1: Envoyer le code
  Future<Map<String, dynamic>> signInWithPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(String error) verificationFailed,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-résolution (Android uniquement)
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage;
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Numéro de téléphone invalide';
              break;
            case 'too-many-requests':
              errorMessage = 'Trop de tentatives. Réessayez plus tard';
              break;
            default:
              errorMessage = e.message ?? 'Erreur de vérification';
          }
          verificationFailed(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          codeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Timeout
        },
        timeout: const Duration(seconds: 60),
      );

      return {
        'success': true,
        'message': 'Code envoyé',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: $e',
      };
    }
  }

  // Authentification par téléphone - Étape 2: Vérifier le code
  Future<Map<String, dynamic>> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
    String? name,
  }) async {
    try {
      // Créer les credentials avec le code SMS
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Se connecter avec les credentials
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        return {
          'success': false,
          'error': 'Échec de la vérification',
        };
      }

      // Créer ou mettre à jour le document utilisateur dans Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        // Nouveau utilisateur
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'phoneNumber': user.phoneNumber,
          'name': name ?? 'Utilisateur',
          'email': user.email ?? '',
          'balance': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isVerified': true,
          'role': 'user',
          'provider': 'phone',
        });
      } else {
        // Utilisateur existant
        await _firestore.collection('users').doc(user.uid).update({
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return {
        'success': true,
        'user': user,
        'message': 'Connexion réussie',
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Code de vérification invalide';
          break;
        case 'session-expired':
          errorMessage = 'La session a expiré. Demandez un nouveau code';
          break;
        default:
          errorMessage = 'Erreur: ${e.message}';
      }
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur inattendue: $e',
      };
    }
  }

  // Supprimer le compte
  Future<Map<String, dynamic>> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return {
          'success': false,
          'error': 'Utilisateur non connecté',
        };
      }

      // Ré-authentifier l'utilisateur
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Supprimer le document Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Supprimer le compte Auth
      await user.delete();

      return {
        'success': true,
        'message': 'Compte supprimé avec succès',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: $e',
      };
    }
  }
}
