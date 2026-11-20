importScripts(
  'https://www.gstatic.com/firebasejs/11.10.0/firebase-app-compat.js',
);
importScripts(
  'https://www.gstatic.com/firebasejs/11.10.0/firebase-messaging-compat.js',
);
importScripts('firebase-messaging-config.js');

firebase.initializeApp(self.firebaseMessagingConfig);
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || 'MyShelf';
  const body = payload.notification?.body || 'You have a new notification.';
  const data = payload.data || {};
  const postTypes = [
    'new_comment',
    'mutual_comment',
    'mutual_post',
    'mutual_rating',
  ];
  const route = postTypes.includes(data.type) && data.targetId
    ? `/community/post/${encodeURIComponent(data.targetId)}`
    : data.actorUid
    ? `/community/profile/${encodeURIComponent(data.actorUid)}`
    : '/notifications';
  self.registration.showNotification(title, { body, data: { route } });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const route = event.notification.data?.route || '/notifications';
  event.waitUntil(
    self.clients.openWindow(new URL(route, self.location.origin).href),
  );
});
