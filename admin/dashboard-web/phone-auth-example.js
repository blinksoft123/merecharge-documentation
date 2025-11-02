// Exemple d'authentification par téléphone Firebase
// À intégrer dans votre application

// Configuration reCAPTCHA
window.recaptchaVerifier = new firebase.auth.RecaptchaVerifier('recaptcha-container', {
    'size': 'normal',
    'callback': (response) => {
        // reCAPTCHA résolu, peut maintenant envoyer SMS
        console.log('reCAPTCHA résolu');
    },
    'expired-callback': () => {
        console.log('reCAPTCHA expiré');
    }
});

// Fonction pour envoyer le code SMS
function sendSMSVerification(phoneNumber) {
    const appVerifier = window.recaptchaVerifier;
    
    firebase.auth().signInWithPhoneNumber(phoneNumber, appVerifier)
        .then((confirmationResult) => {
            // SMS envoyé avec succès
            window.confirmationResult = confirmationResult;
            console.log('SMS envoyé avec succès');
            
            // Afficher le champ pour saisir le code
            showCodeVerificationUI();
        })
        .catch((error) => {
            console.error('Erreur lors de l\'envoi du SMS:', error);
            
            // Messages d'erreur courants
            if (error.code === 'auth/invalid-phone-number') {
                alert('Numéro de téléphone invalide');
            } else if (error.code === 'auth/operation-not-allowed') {
                alert('L\'authentification par téléphone n\'est pas activée');
            } else if (error.code === 'auth/quota-exceeded') {
                alert('Quota SMS dépassé');
            }
        });
}

// Fonction pour vérifier le code SMS
function verifyCode(code) {
    const credential = firebase.auth.PhoneAuthProvider.credential(
        window.confirmationResult.verificationId, 
        code
    );
    
    firebase.auth().signInWithCredential(credential)
        .then((result) => {
            console.log('Authentification réussie:', result.user);
            // Rediriger vers l'application
            window.location.href = '/dashboard';
        })
        .catch((error) => {
            console.error('Erreur de vérification:', error);
            
            if (error.code === 'auth/invalid-verification-code') {
                alert('Code de vérification invalide');
            } else if (error.code === 'auth/code-expired') {
                alert('Code de vérification expiré');
            }
        });
}

// HTML requis dans votre page
/*
<div id="recaptcha-container"></div>
<input type="tel" id="phone-number" placeholder="+237698123456">
<button onclick="sendSMS()">Envoyer SMS</button>

<div id="code-verification" style="display:none;">
    <input type="text" id="verification-code" placeholder="123456">
    <button onclick="verifyCode()">Vérifier</button>
</div>
*/

// Fonctions utilitaires
function sendSMS() {
    const phoneNumber = document.getElementById('phone-number').value;
    
    // Validation du format
    if (!phoneNumber.startsWith('+')) {
        alert('Le numéro doit commencer par un indicatif pays (ex: +237)');
        return;
    }
    
    sendSMSVerification(phoneNumber);
}

function showCodeVerificationUI() {
    document.getElementById('code-verification').style.display = 'block';
}

function verifyCodeFromInput() {
    const code = document.getElementById('verification-code').value;
    if (code.length === 6) {
        verifyCode(code);
    } else {
        alert('Le code doit contenir 6 chiffres');
    }
}