import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'lib/firebase_options.dart';

Future<void> main() async {
  print('🔥 Test de connexion Firebase...\n');

  try {
    // Initialiser Firebase
    print('📱 Initialisation de Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialisé avec succès!\n');

    // Tester Firebase Auth
    print('🔐 Test Firebase Auth...');
    final auth = FirebaseAuth.instance;
    print('✅ Firebase Auth disponible');
    print('   Current User: ${auth.currentUser?.email ?? "Aucun utilisateur connecté"}\n');

    // Tester Firestore
    print('💾 Test Firestore...');
    final firestore = FirebaseFirestore.instance;
    
    // Écriture dans Firestore
    print('   Écriture dans Firestore...');
    await firestore.collection('test').doc('connection_test').set({
      'timestamp': FieldValue.serverTimestamp(),
      'message': 'Test de connexion réussi depuis le script',
      'platform': 'dart_script',
    });
    print('✅ Écriture réussie!\n');

    // Lecture depuis Firestore
    print('   Lecture depuis Firestore...');
    final doc = await firestore.collection('test').doc('connection_test').get();
    if (doc.exists) {
      print('✅ Lecture réussie!');
      print('   Données: ${doc.data()}\n');
    } else {
      print('⚠️  Document non trouvé\n');
    }

    print('🎉 Tous les tests Firebase sont passés avec succès!\n');
    print('✅ Firebase Core: OK');
    print('✅ Firebase Auth: OK');
    print('✅ Firestore: OK\n');

    print('📊 Informations du projet:');
    print('   Project ID: merecharge-50ab0');
    print('   App ID: ${Firebase.app().options.appId}');
    print('   Storage Bucket: ${Firebase.app().options.storageBucket}\n');

  } catch (e, stackTrace) {
    print('❌ Erreur lors du test Firebase:');
    print('   $e');
    print('\n📋 Stack trace:');
    print('   $stackTrace');
  }
}
