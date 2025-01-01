// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationStore } from '#shared/stores/application.ts'

import { TicketSidebarScreenType } from '../../../types/sidebar.ts'
import TicketSidebarChecklist from '../TicketSidebarChecklist/TicketSidebarChecklist.vue'

import type { TicketSidebarPlugin } from './types.ts'

export default <TicketSidebarPlugin>{
  title: __('Checklist'),
  component: TicketSidebarChecklist,
  permissions: ['ticket.agent'],
  screens: [TicketSidebarScreenType.TicketDetailView],
  icon: 'checklist',
  order: 5000,
  available: () => {
    const { config } = useApplicationStore()

    return Boolean(config.checklist)
  },
}
