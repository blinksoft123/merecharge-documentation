const crypto = require('crypto-js');
require('dotenv').config();

function debugAuthGeneration() {
  const token = process.env.S3P_KEY;
  const secret = process.env.S3P_SECRET;
  const baseURL = process.env.S3P_URL;
  
  console.log('=== Debug de l\'authentification ===');
  console.log('Token:', token);
  console.log('Secret:', secret ? secret.substring(0, 8) + '...' : 'undefined');
  console.log('Base URL:', baseURL);
  console.log('');

  // Simuler la génération de l'en-tête d'auth pour ping
  const method = 'GET';
  const url = `${baseURL}/ping`;
  const params = {};

  const timestamp = Date.now();
  const nonce = Date.now();
  
  const s3pParams = {
    s3pAuth_nonce: nonce,
    s3pAuth_timestamp: timestamp,
    s3pAuth_signature_method: 'HMAC-SHA1',
    s3pAuth_token: token
  };

  const allParams = { ...params, ...s3pParams };
  
  // Nettoie les paramètres (trim les strings)
  Object.keys(allParams).forEach(key => {
    if (typeof allParams[key] === 'string') {
      allParams[key] = allParams[key].trim();
    }
  });

  // Trie les paramètres par ordre alphabétique
  const sortedParams = Object.keys(allParams)
    .sort()
    .reduce((result, key) => {
      result[key] = allParams[key];
      return result;
    }, {});

  // Crée la chaîne de paramètres
  const parameterString = Object.keys(sortedParams)
    .map(key => `${key}=${sortedParams[key]}`)
    .join('&');

  // Crée la base string pour la signature
  const baseString = `${method}&${encodeURIComponent(url)}&${encodeURIComponent(parameterString)}`;
  
  console.log('Paramètres triés:', sortedParams);
  console.log('Parameter string:', parameterString);
  console.log('Base string:', baseString);
  console.log('');
  
  // Génère la signature HMAC-SHA1
  const signature = crypto.HmacSHA1(baseString, secret);
  const encodedSignature = crypto.enc.Base64.stringify(signature);

  console.log('Signature brute:', signature.toString());
  console.log('Signature encodée:', encodedSignature);
  console.log('');

  // Construit l'en-tête d'autorisation
  const authHeader = `s3pAuth s3pAuth_timestamp="${timestamp}", s3pAuth_signature="${encodedSignature}", s3pAuth_nonce="${nonce}", s3pAuth_signature_method="HMAC-SHA1", s3pAuth_token="${token}"`;

  console.log('En-tête d\'autorisation:', authHeader);
  console.log('');
  
  // Test de comparaison avec l'exemple Postman
  console.log('=== Comparaison avec l\'exemple Postman ===');
  console.log('Format attendu selon Postman:');
  console.log('s3pAuth s3pAuth_timestamp="[timestamp]", s3pAuth_signature="[signature]", s3pAuth_nonce="[nonce]", s3pAuth_signature_method="HMAC-SHA1", s3pAuth_token="[token]"');
  console.log('');
  console.log('Notre format:');
  console.log(authHeader);
}

debugAuthGeneration();