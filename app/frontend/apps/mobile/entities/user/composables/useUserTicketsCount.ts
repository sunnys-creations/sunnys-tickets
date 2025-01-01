// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { TicketCount } from '#shared/graphql/types.ts'

interface RequiredUser {
  id: string
  internalId: number
  ticketsCount?: Maybe<TicketCount>
}

export const useUsersTicketsCount = () => {
  const getTicketData = (user?: Maybe<RequiredUser>) => {
    if (!user || !user.ticketsCount) return null
    return {
      count: user.ticketsCount,
      createLabel: __('Create new ticket for this user'),
      createLink: `/tickets/create?customer_id=${user.internalId}`,
      query: `customer.id: ${user.internalId}`,
    }
  }

  return { getTicketData }
}
