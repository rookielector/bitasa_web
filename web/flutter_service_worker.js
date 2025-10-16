'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  "main.dart.js": "82f8a8bbd12903274640d21097228833",
  "index.html": "495f59047321e05d3513a80695034c57",
  "assets/AssetManifest.json": "6a3c948011c34a45bac741b57502c332",
  "assets/FontManifest.json": "dc3d04f17c4e5113d332c6680a3c20c0",
  "assets/NOTICES": "f295175591d5757270f803c58e0a7863",
  "favicon.png": "b8f04b212f71f11bd3d17871e0c6f510",
  "icons/Icon-192.png": "1e75459392e21b723e784651336d8591",
  "icons/Icon-512.png": "38a3791a8b9f71c4801e85579f109267",
  "icons/Icon-maskable-192.png": "d8206d2c1e8787f1390457d598e91024",
  "icons/Icon-maskable-512.png": "7130b05b63013b94d13e2d63321590fb",
  "manifest.json": "36d2466f91752b57a7d4323267562f90",
  "assets/images/logo.webp": "7d934145719a6b6f790c3779e56ab9a3",
  "assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "422f25492d537d8d08596f264758d6b7",
  "assets/fonts/MaterialIcons-Regular.otf": "61a12132f4165d33ec6087d157a81b21",
  "canvaskit/canvaskit.js": "8c6d4e59ae92942b03cadb11029c4033",
  "canvaskit/canvaskit.wasm": "5b4588e7b952f99eb662243d543e493f",
  "canvaskit/profiling/canvaskit.js": "a24449831d1d2340578842e61a665269",
  "canvaskit/profiling/canvaskit.wasm": "426b38c4125a07c4fa48956914570b5c",
  "/": "495f59047321e05d3513a80695034c57"
};

const CORE = [
  "/",
  "main.dart.js",
  "index.html",
  "assets/AssetManifest.json",
  "assets/FontManifest.json"
];

self.addEventListener("install", (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(CORE);
    })
  );
});

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

self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin) {
    return;
  }
  if (CORE.includes(url.pathname)) {
    event.respondWith(
      caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          return response || fetch(event.request);
        });
      })
    );
    return;
  }
  event.respondWith(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.match(event.request).then((response) => {
        if (response) {
          return response;
        }
        return fetch(event.request).then((response) => {
          if (response.ok) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      });
    })
  );
});