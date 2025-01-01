// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import UserItem from '#mobile/components/User/UserItem.vue'

import type { SearchPlugin } from './index.ts'

export default <SearchPlugin>{
  model: 'User',
  headerLabel: __('Users'),
  searchLabel: __('Users with "%s"'),
  component: UserItem,
  order: 200,
  link: '/users/#{internalId}',
  permissions: ['ticket.agent'],
  icon: { name: 'person', size: 'base' },
  iconBg: 'bg-pink',
}
