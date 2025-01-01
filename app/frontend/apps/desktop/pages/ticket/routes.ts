// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { EnumTaskbarEntity } from '#shared/graphql/types.ts'

import type { RouteRecordRaw } from 'vue-router'

const route: RouteRecordRaw[] = [
  {
    path: '/tickets/create/:tabId?',
    name: 'TicketCreate',
    props: true,
    component: () => import('./views/TicketCreate.vue'),
    alias: ['/ticket/create/:tabId?', '/ticket/create/:pathMatch(.*)*'],
    meta: {
      title: __('New Ticket'),
      requiresAuth: true,
      requiredPermission: ['ticket.agent', 'ticket.customer'],
      taskbarTabEntity: EnumTaskbarEntity.TicketCreate,
      level: 2,
    },
  },
  {
    path: '/tickets/:internalId(\\d+)',
    alias: ['/ticket/:internalId(\\d+)', '/ticket/zoom/:internalId(\\d+)'],
    name: 'TicketDetail',
    props: true,
    component: () => import('./views/TicketDetailView.vue'),
    meta: {
      title: __('Ticket'),
      requiresAuth: true,
      requiredPermission: ['ticket.agent', 'ticket.customer'],
      taskbarTabEntity: EnumTaskbarEntity.TicketZoom,
      level: 2,
    },
  },
  {
    path: '/ticket/zoom/:internalId(\\d+)/:articleId(\\d+)',
    redirect: (to) =>
      `/tickets/${to.params.internalId}#article-${to.params.articleId}`,
  },
  {
    path: '/tickets/:internalId(\\d+)/:articleId(\\d+)',
    redirect: (to) =>
      `/tickets/${to.params.internalId}#article-${to.params.articleId}`,
  },
]

export default route
