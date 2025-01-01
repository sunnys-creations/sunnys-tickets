// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { TicketInformationPlugin } from './index.ts'

export default <TicketInformationPlugin>{
  label: __('Ticket'),
  route: {
    path: '',
    name: 'TicketInformationDetails',
    component: () => import('../TicketInformationDetails.vue'),
    meta: {
      requiresAuth: true,
      requiredPermission: [],
    },
  },
  order: 100,
}
