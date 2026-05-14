const admin = require('firebase-admin');

admin.initializeApp();

async function setAdminClaim() {
    await admin.auth().setCustomUserClaims('8zgCWSp7cBXuw4rS9UtdGcwFZTk2', {
        role: 'admin',
        admin: true,
    });

    console.log('Admin claim başarıyla ayarlandı.');
}

setAdminClaim().catch(console.error);