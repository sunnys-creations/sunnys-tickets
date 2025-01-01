// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { expect } from 'vitest'

import {
  getByIconName,
  queryByIconName,
} from '#tests/support/components/iconQueries.ts'
import { visitView } from '#tests/support/components/visitView.ts'

import { mockTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.mocks.ts'
import { getTicketLiveUserUpdatesSubscriptionHandler } from '#shared/entities/ticket/graphql/subscriptions/ticketLiveUserUpdates.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import { EnumTaskbarApp } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

vi.hoisted(() => {
  vi.setSystemTime(new Date('2024-09-19T09:06:00Z'))
})

describe('Ticket detail view live users handling', () => {
  beforeEach(() => {
    mockTicketQuery({ ticket: createDummyTicket() })
  })

  it('displays idle state of the user avatar', async () => {
    const view = await visitView('/tickets/1')

    await getTicketLiveUserUpdatesSubscriptionHandler().trigger({
      ticketLiveUserUpdates: {
        liveUsers: [
          {
            user: {
              id: convertToGraphQLId('User', 3),
              firstname: 'Nicole',
              lastname: 'Braun',
              fullname: 'Nicole Braun',
              vip: true,
            },
            apps: [
              {
                name: EnumTaskbarApp.Desktop,
                editing: false,
                lastInteraction: '2024-09-19T09:00:00Z',
              },
            ],
          },
        ],
      },
    })

    const customerAvatar = await view.findByRole('img', {
      name: 'Avatar (Nicole Braun) (VIP)',
    })

    expect(customerAvatar.parentElement!).toHaveClasses([
      'opacity-50',
      'grayscale',
    ])

    await getTicketLiveUserUpdatesSubscriptionHandler().trigger({
      ticketLiveUserUpdates: {
        liveUsers: [
          {
            user: {
              id: convertToGraphQLId('User', 3),
              firstname: 'Nicole',
              lastname: 'Braun',
              fullname: 'Nicole Braun',
              vip: true,
            },
            apps: [
              {
                name: EnumTaskbarApp.Desktop,
                editing: false,
                lastInteraction: '2024-09-19T09:05:00Z',
              },
            ],
          },
        ],
      },
    })

    expect(customerAvatar.parentElement!).not.toHaveClasses([
      'opacity-50',
      'grayscale',
    ])
  })

  it('displays icon on user avatar if they are editing', async () => {
    const view = await visitView('/tickets/1')

    await getTicketLiveUserUpdatesSubscriptionHandler().trigger({
      ticketLiveUserUpdates: {
        liveUsers: [
          {
            user: {
              id: convertToGraphQLId('User', 3),
              firstname: 'Nicole',
              lastname: 'Braun',
              fullname: 'Nicole Braun',
              vip: true,
            },
            apps: [
              {
                name: EnumTaskbarApp.Desktop,
                editing: false,
                lastInteraction: '2024-09-19T09:00:00Z',
              },
            ],
          },
        ],
      },
    })

    const customerAvatar = await view.findByRole('img', {
      name: 'Avatar (Nicole Braun) (VIP)',
    })

    expect(
      queryByIconName(customerAvatar.parentElement!, 'pencil'),
    ).not.toBeInTheDocument()

    await getTicketLiveUserUpdatesSubscriptionHandler().trigger({
      ticketLiveUserUpdates: {
        liveUsers: [
          {
            user: {
              id: convertToGraphQLId('User', 3),
              firstname: 'Nicole',
              lastname: 'Braun',
              fullname: 'Nicole Braun',
              vip: true,
            },
            apps: [
              {
                name: EnumTaskbarApp.Desktop,
                editing: true,
                lastInteraction: '2024-09-19T09:05:00Z',
              },
            ],
          },
        ],
      },
    })

    expect(
      getByIconName(customerAvatar.parentElement!, 'pencil'),
    ).toBeInTheDocument()
  })

  it('displays icon on user avatar if they are on mobile', async () => {
    const view = await visitView('/tickets/1')

    await getTicketLiveUserUpdatesSubscriptionHandler().trigger({
      ticketLiveUserUpdates: {
        liveUsers: [
          {
            user: {
              id: convertToGraphQLId('User', 3),
              firstname: 'Nicole',
              lastname: 'Braun',
              fullname: 'Nicole Braun',
              vip: true,
            },
            apps: [
              {
                name: EnumTaskbarApp.Desktop,
                editing: false,
                lastInteraction: '2024-09-19T09:00:00Z',
              },
            ],
          },
        ],
      },
    })

    const customerAvatar = await view.findByRole('img', {
      name: 'Avatar (Nicole Braun) (VIP)',
    })

    expect(
      queryByIconName(customerAvatar.parentElement!, 'phone'),
    ).not.toBeInTheDocument()

    await getTicketLiveUserUpdatesSubscriptionHandler().trigger({
      ticketLiveUserUpdates: {
        liveUsers: [
          {
            user: {
              id: convertToGraphQLId('User', 3),
              firstname: 'Nicole',
              lastname: 'Braun',
              fullname: 'Nicole Braun',
              vip: true,
            },
            apps: [
              {
                name: EnumTaskbarApp.Mobile,
                editing: false,
                lastInteraction: '2024-09-19T09:05:00Z',
              },
            ],
          },
        ],
      },
    })

    expect(
      getByIconName(customerAvatar.parentElement!, 'phone'),
    ).toBeInTheDocument()
  })

  it('hides the user avatar if they leave the ticket', async () => {
    const view = await visitView('/tickets/1')

    await getTicketLiveUserUpdatesSubscriptionHandler().trigger({
      ticketLiveUserUpdates: {
        liveUsers: [
          {
            user: {
              id: convertToGraphQLId('User', 3),
              firstname: 'Nicole',
              lastname: 'Braun',
              fullname: 'Nicole Braun',
              vip: true,
            },
            apps: [
              {
                name: EnumTaskbarApp.Desktop,
                editing: false,
                lastInteraction: '2024-09-19T09:00:00Z',
              },
            ],
          },
        ],
      },
    })

    expect(
      await view.findByRole('img', {
        name: 'Avatar (Nicole Braun) (VIP)',
      }),
    ).toBeInTheDocument()

    await getTicketLiveUserUpdatesSubscriptionHandler().trigger({
      ticketLiveUserUpdates: {
        liveUsers: [],
      },
    })

    expect(
      view.queryByRole('img', { name: 'Avatar (Nicole Braun) (VIP)' }),
    ).not.toBeInTheDocument()
  })
})
