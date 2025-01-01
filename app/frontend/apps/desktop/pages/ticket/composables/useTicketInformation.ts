// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { computed, inject, provide } from 'vue'

import { useTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.api.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import { useErrorHandler } from '#shared/errors/useErrorHandler.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import type { TicketInformation } from '#desktop/entities/ticket/types.ts'

import type { Ref, InjectionKey } from 'vue'

export const TICKET_KEY = Symbol('ticket') as InjectionKey<TicketInformation>

export const initializeTicketInformation = (
  internalId: Ref<number | string>,
) => {
  const ticketId = computed(() =>
    convertToGraphQLId('Ticket', internalId.value),
  )

  // TODO: stay with his for now, but need to be re-implemented for the tab situation.
  const { createQueryErrorHandler } = useErrorHandler()

  const ticketQuery = new QueryHandler(
    // Currently we need no subscribeToMore here, because the tab registration holds the ticket subscription.
    useTicketQuery(
      () => ({
        ticketId: ticketId.value,
      }),
      { fetchPolicy: 'cache-first' },
    ),
    {
      errorCallback: createQueryErrorHandler({
        notFound: __(
          'Ticket with specified ID was not found. Try checking the URL for errors.',
        ),
        forbidden: __('You have insufficient rights to view this ticket.'),
      }),
    },
  )

  const result = ticketQuery.result()

  const ticket = computed(() => result.value?.ticket as TicketById)

  return {
    ticket,
    ticketId,
    ticketInternalId: internalId as Ref<number>,
  }
}

export const provideTicketInformation = (data: TicketInformation) => {
  provide(TICKET_KEY, data)
}

export const useTicketInformation = () => {
  return inject(TICKET_KEY) as TicketInformation
}
