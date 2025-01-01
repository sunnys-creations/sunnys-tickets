// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { axe } from 'vitest-axe'

import { visitView } from '#tests/support/components/visitView.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import {
  mockTicketSharedDraftStartListQuery,
  waitForTicketSharedDraftStartListQueryCalls,
} from '#shared/entities/ticket-shared-draft-start/graphql/queries/ticketSharedDraftStartList.mocks.ts'
import { waitForUserQueryCalls } from '#shared/entities/user/graphql/queries/user.mocks.ts'

import { mockUserCurrentTaskbarItemListQuery } from '#desktop/entities/user/current/graphql/queries/userCurrentTaskbarItemList.mocks.ts'
import {
  handleMockFormUpdaterQuery,
  handleMockOrganizationQuery,
  handleMockUserQuery,
} from '#desktop/pages/ticket/__tests__/support/ticket-create-helpers.ts'

describe('testing tickets create a11y view', async () => {
  beforeEach(() => {
    mockApplicationConfig({
      ui_ticket_create_available_types: ['phone-in', 'phone-out', 'email-out'],
      customer_ticket_create: true,
    })
    mockPermissions(['ticket.agent'])
    mockUserCurrentTaskbarItemListQuery({
      userCurrentTaskbarItemList: [],
    })
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('has no accessibility violations in main content', async () => {
    handleMockFormUpdaterQuery()

    const view = await visitView('/tickets/create')

    const results = await axe(view.html())

    expect(results).toHaveNoViolations()
  })

  it('has no accessibility violations in customer sidebar', async () => {
    handleMockFormUpdaterQuery({
      customer_id: {
        value: 2,
      },
    })

    handleMockUserQuery()

    const view = await visitView('/tickets/create')

    await waitForUserQueryCalls()

    await waitFor(() => {
      expect(
        view.getByRole('complementary', {
          name: 'Content sidebar',
        }),
      ).toBeInTheDocument()
    })

    const results = await axe(view.html())

    expect(results).toHaveNoViolations()
  })

  it('has no accessibility violations in organization sidebar', async () => {
    handleMockFormUpdaterQuery({
      customer_id: {
        value: 2,
        options: [
          {
            value: 2,
            label: 'Nicole Braun',
            heading: 'Zammad Foundation',
          },
        ],
      },
    })

    handleMockUserQuery()

    const view = await visitView('/tickets/create', {
      global: {
        stubs: {
          'transition-group': false,
        },
      },
    })

    await waitForUserQueryCalls()

    await waitFor(() => {
      expect(
        view.getByRole('complementary', {
          name: 'Content sidebar',
        }),
      ).toBeInTheDocument()
    })

    handleMockOrganizationQuery()

    await view.events.click(view.getByLabelText('Organization'))

    const results = await axe(view.html())

    expect(results).toHaveNoViolations()
  })

  it('has no accessibility violations in shared drafts sidebar', async () => {
    handleMockFormUpdaterQuery({
      group_id: {
        value: 1,
        options: [
          {
            value: 1,
            label: 'Users',
          },
        ],
      },
    })

    mockTicketSharedDraftStartListQuery({
      ticketSharedDraftStartList: [],
    })

    const view = await visitView('/tickets/create')

    await waitForTicketSharedDraftStartListQueryCalls()

    await waitFor(() => {
      expect(
        view.getByRole('complementary', {
          name: 'Content sidebar',
        }),
      ).toBeInTheDocument()
    })

    const results = await axe(view.html())

    expect(results).toHaveNoViolations()
  })
})
