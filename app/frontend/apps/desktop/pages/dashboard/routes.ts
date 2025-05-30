// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { RouteRecordRaw } from 'vue-router'

const route: RouteRecordRaw[] = [
  {
    path: '/playground',
    name: 'Playground',
    props: true,
    component: () => import('./views/Playground.vue'),
    meta: {
      title: 'Playground',
      icon: 'logo-flat',
      requiresAuth: true,
      requiredPermission: ['admin'],
      order: 500,
    },
  },
]

// Temporary until we work on the dashboard
if (import.meta.env.DEV || VITE_TEST_MODE) {
  route.push({
    path: '/dashboard',
    name: 'Dashboard',
    alias: '/',
    props: true,
    component: () => import('./views/Dashboard.vue'),
    meta: {
      title: __('Dashboard'),
      requiresAuth: true,
      icon: 'speedometer2',
      requiredPermission: ['*'],
      order: 0,
      level: 1,
      permanentItem: true,
    },
  })
}

export default route
