importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCTCbGBlsVLOg1fsCSXUfPwymyGwBYjq-k",
  authDomain: "hospital-appointment-51250.firebaseapp.com",
  databaseURL: "https://hospital-appointment-51250-default-rtdb.firebaseio.com",
  projectId: "hospital-appointment-51250",
  storageBucket: "hospital-appointment-51250.firebasestorage.app",
  messagingSenderId: "862995028469",
  appId: "1:862995028469:web:047cb99b19645fcdf1e8bc",
  measurementId: "G-V65H3K71LV"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message: ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
