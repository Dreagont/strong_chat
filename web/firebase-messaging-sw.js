importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

const firebaseConfig = {
   apiKey: "AIzaSyAziDbyTEhgpHNNJqVXiVEI5nzwf-3s4Zc",
   authDomain: "flutter-final-app-bcd9d.firebaseapp.com",
   databaseURL: "https://flutter-final-app-bcd9d-default-rtdb.firebaseio.com",
   projectId: "flutter-final-app-bcd9d",
   storageBucket: "flutter-final-app-bcd9d.appspot.com",
   messagingSenderId: "1093443293754",
   appId: "1:1093443293754:web:d866244f10c17006f29b03",
   measurementId: "G-3Z1Z784BPR"
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
  console.log('Received background message ', payload);
//  const notificationTitle = payload.notification.title;
//  const notificationOptions = {
//    body: payload.notification.body,
//    icon: '/favicon.png',
//  };
//
//  self.registration.showNotification(notificationTitle, notificationOptions);

});