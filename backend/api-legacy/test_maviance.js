const MavianceService = require('./maviance_service');

async function testMavianceIntegration() {
  console.log('=== Test de l\'intégration Maviance ===\n');
  
  const mavianceService = new MavianceService();

  // Test 1: Ping
  console.log('1. Test de ping...');
  try {
    const pingResult = await mavianceService.ping();
    if (pingResult.success) {
      console.log('✅ Ping réussi:', pingResult.data);
    } else {
      console.log('❌ Ping échoué:', pingResult.error);
    }
  } catch (error) {
    console.log('❌ Erreur ping:', error.message);
  }
  console.log('');

  // Test 2: Récupération des services
  console.log('2. Test de récupération des services...');
  try {
    const servicesResult = await mavianceService.getServices();
    if (servicesResult.success) {
      console.log('✅ Services récupérés avec succès');
      console.log('Nombre de services disponibles:', servicesResult.data?.length || 'N/A');
      if (servicesResult.data && servicesResult.data.length > 0) {
        console.log('Exemple de service:', servicesResult.data[0]);
      }
    } else {
      console.log('❌ Échec récupération services:', servicesResult.error);
    }
  } catch (error) {
    console.log('❌ Erreur services:', error.message);
  }
  console.log('');

  // Test 3: Récupération des produits TOPUP (Orange)
  console.log('3. Test de récupération des produits TOPUP Orange...');
  try {
    const topupResult = await mavianceService.getTopupProducts('20062'); // Orange service ID from Postman
    if (topupResult.success) {
      console.log('✅ Produits TOPUP récupérés avec succès');
      console.log('Nombre de produits:', topupResult.data?.length || 'N/A');
      if (topupResult.data && topupResult.data.length > 0) {
        console.log('Exemple de produit:', topupResult.data[0]);
      }
    } else {
      console.log('❌ Échec récupération TOPUP:', topupResult.error);
    }
  } catch (error) {
    console.log('❌ Erreur TOPUP:', error.message);
  }
  console.log('');

  // Test 4: Création d'un devis (quote) de test
  console.log('4. Test de création d\'un devis...');
  try {
    // Utilisation d'un payItemId d'exemple de la collection Postman
    const quoteResult = await mavianceService.createQuote('S-112-951-CMORANGE-20062-CM_ORANGE_VTU_CUSTOM-1', 1000);
    if (quoteResult.success) {
      console.log('✅ Devis créé avec succès');
      console.log('Quote ID:', quoteResult.data.quoteId);
      console.log('Détails du devis:', quoteResult.data);
    } else {
      console.log('❌ Échec création devis:', quoteResult.error);
    }
  } catch (error) {
    console.log('❌ Erreur devis:', error.message);
  }
  console.log('');

  console.log('=== Tests terminés ===');
}

// Lancer les tests
testMavianceIntegration().catch(console.error);