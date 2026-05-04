importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyA6h5oQca4uezX5FqWh4E758KRnLxxnJJE",
  authDomain: "amedsporapp.firebaseapp.com",
  projectId: "amedsporapp",
  storageBucket: "amedsporapp.firebasestorage.app",
  messagingSenderId: "346583132476",
  appId: "1:346583132476:web:5f9066f1ef53a97de41639",
  measurementId: "G-MPZ4J15WH1"
});

const messaging = firebase.messaging();