const admin = require("firebase-admin");

admin.initializeApp({
    projectId: "amedsporapp",
});

async function main() {
    await admin.auth().setCustomUserClaims("8zgCWSp7cBXuw4rS9UtdGcwFZTk2", {
        role: "admin",
    });

    console.log("Admin claim başarıyla ayarlandı.");
}

main().catch(console.error);
