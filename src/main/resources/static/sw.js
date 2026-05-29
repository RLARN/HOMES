// ^HOMES Service Worker
self.addEventListener('push', function (event) {
    let data = { title: '^HOMES 알림', body: '', url: '/' };
    try {
        if (event.data) data = Object.assign(data, event.data.json());
    } catch (_) {}

    event.waitUntil(
        self.registration.showNotification(data.title, {
            body:  data.body,
            icon:  '/favicon.ico',
            badge: '/favicon.ico',
            tag:   'homes-push',
            data:  { url: data.url }
        })
    );
});

self.addEventListener('notificationclick', function (event) {
    event.notification.close();
    const url = (event.notification.data && event.notification.data.url) || '/';
    event.waitUntil(
        clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (list) {
            for (const client of list) {
                if (client.url.includes(url) && 'focus' in client) return client.focus();
            }
            return clients.openWindow(url);
        })
    );
});
