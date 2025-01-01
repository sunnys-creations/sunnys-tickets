// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'

import { useTicketQuery } from '#shared/entities/ticket/graphql/queries/ticket.api.ts'
import { useErrorHandler } from '#shared/errors/useErrorHandler.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

export const useTicketDataHandler = (ticketId: Ref<string>) => {
  const { createQueryErrorHandler } = useErrorHandler()

  const ticketQuery = new QueryHandler(
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

  const ticketResult = ticketQuery.result()

  const isLoadingTicket = computed(() => {
    return ticketQuery.loading().value && !ticketResult.value
  })

  const isRefetchingTicket = computed(
    () => ticketQuery.loading().value && !!ticketResult.value,
  )

  return { ticketQuery, ticketResult, isRefetchingTicket, isLoadingTicket }
}
