importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'TODO_FIREBASE_WEB_API_KEY',
  appId: 'TODO_FIREBASE_WEB_APP_ID',
  messagingSenderId: '354206024941',
  projectId: 'alcoholimetro',
});

const messaging = firebase.messaging();
