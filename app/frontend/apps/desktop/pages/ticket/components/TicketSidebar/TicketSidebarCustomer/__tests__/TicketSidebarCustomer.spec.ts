// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { cleanup } from '@testing-library/vue'
import { computed, ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import {
  mockUserQuery,
  waitForUserQueryCalls,
} from '#shared/entities/user/graphql/queries/user.mocks.ts'

import { TICKET_KEY } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

import { TicketSidebarScreenType } from '../../../../types/sidebar.ts'
import customerSidebarPlugin from '../../plugins/customer.ts'
import TicketSidebarCustomer from '../TicketSidebarCustomer.vue'

const renderTicketSidebarCustomer = async (
  context: {
    formValues: Record<string, unknown>
  },
  options: any = {},
) => {
  const result = renderComponent(TicketSidebarCustomer, {
    props: {
      sidebar: 'customer',
      sidebarPlugin: customerSidebarPlugin,
      selected: true,
      context: {
        screenType: TicketSidebarScreenType.TicketCreate,
        ...context,
      },
    },
    router: true,
    plugins: [
      (app) => {
        const ticket = createDummyTicket()
        app.provide(TICKET_KEY, {
          ticketId: computed(() => ticket.id),
          ticket: computed(() => ticket),
          form: ref(),
          showTicketArticleReplyForm: () => {},
          isTicketEditable: computed(() => true),
          newTicketArticlePresent: ref(false),
          ticketInternalId: computed(() => ticket.internalId),
        })
      },
    ],
    global: {
      stubs: {
        teleport: true,
      },
    },
    ...options,
  })

  if (context.formValues.customer_id) await waitForUserQueryCalls()

  await waitForNextTick()

  return result
}

describe('TicketSidebarCustomer.vue', () => {
  afterEach(() => {
    // :TODO write a cleanup inside of the renderComponent to avoid
    // :ERROR App already provides property with key "Symbol(ticket)". It will be overwritten with the new value
    // Missing cleanup in test env
    // It is still getting logged as warnings
    cleanup()
    vi.clearAllMocks()
  })

  it('shows sidebar when customer ID is present', async () => {
    const wrapper = await renderTicketSidebarCustomer({
      formValues: {
        customer_id: 2,
      },
    })

    expect(wrapper.emitted('show')).toHaveLength(1)
  })

  it('does not show sidebar when customer ID is absent', async () => {
    const wrapper = await renderTicketSidebarCustomer({
      formValues: {
        customer_id: null,
      },
    })

    expect(wrapper.emitted('show')).toBeUndefined()
  })

  it('hides sidebar when customer got removed', async () => {
    const wrapper = await renderTicketSidebarCustomer({
      formValues: {
        customer_id: 2,
      },
    })

    expect(wrapper.emitted('show')).toHaveLength(1)

    await wrapper.rerender({
      context: {
        formValues: {
          customer_id: null,
        },
      },
    })

    expect(wrapper.emitted('hide')).toHaveLength(1)
  })

  it('displays badge with open ticket count', async () => {
    mockApplicationConfig({
      ui_sidebar_open_ticket_indicator_colored: true,
    })

    mockUserQuery({
      user: {
        ticketsCount: {
          open: 42,
        },
      },
    })

    const wrapper = await renderTicketSidebarCustomer({
      formValues: {
        customer_id: 1,
      },
    })

    const badge = wrapper.getByRole('status', { name: 'Open tickets' })

    expect(badge).toHaveTextContent('42')
    expect(badge).toHaveClass('bg-red-500')
  })
})
