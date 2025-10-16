'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  // Esta sección es un placeholder. El build la reemplazará.
  // Pero para el desarrollo local, es suficiente con que exista.
  "/": "index.html",
};

const CORE = [
  "/",
  "main.dart.js",
  "index.html",
  "assets/AssetManifest.json",
  "assets/FontManifest.json"
];

// Instala el Service Worker y cachea los recursos principales.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(CORE.map(url => new URL(url, self.location).toString()));
    })
  );
});

// Limpia las cachés antiguas.
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.filter((cacheName) => {
          return cacheName.startsWith('flutter-') && cacheName !== CACHE_NAME;
        }).map((cacheName) => {
          return caches.delete(cacheName);
        })
      );
    })
  );
});

// Intercepta las peticiones de red (fetch).
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  const url = new URL(event.request.url);

  // Si la petición es para un recurso del "núcleo", sírvelo desde la caché primero.
  if (CORE.includes(url.pathname)) {
    event.respondWith(
      caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          // Si está en la caché, devuélvelo. Si no, búscalo en la red.
          return response || fetch(event.request);
        });
      })
    );
    return;
  }

  // Para cualquier otro recurso, intenta buscar en la red primero,
  // y si falla, busca en la caché (estrategia network-first).
  event.respondWith(
    fetch(event.request).catch((_) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request);
      });
    })
  );
});