// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/
/* eslint-disable no-restricted-globals */

import { clientsClaim } from 'workbox-core'
import { cleanupOutdatedCaches, precacheAndRoute } from 'workbox-precaching'

declare let self: ServiceWorkerGlobalScope

self.skipWaiting()
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') self.skipWaiting()
})

clientsClaim()
cleanupOutdatedCaches()

if (import.meta.env.MODE !== 'development') {
  precacheAndRoute(
    self.__WB_MANIFEST.map((entry) => {
      const base = import.meta.env.VITE_RUBY_PUBLIC_OUTPUT_DIR
      // this is relative to service worker script, which is
      // located in /mobile/sw.js
      // assets are loaded as /vite/assets/...
      // in the future we will probably have service worker in root
      if (typeof entry === 'string') return `../${base}/${entry}`
      return { ...entry, url: `../${base}/${entry.url}` }
    }),
  )
}

if (import.meta.env.MODE === 'development') {
  console.groupCollapsed("Service worker doesn't precache in development mode")
  self.__WB_MANIFEST.forEach((entry) =>
    console.log(typeof entry === 'string' ? entry : entry.url),
  )
  console.groupEnd()
  precacheAndRoute([])
}
