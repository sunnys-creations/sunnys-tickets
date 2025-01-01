// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { provideApolloClient } from '@vue/apollo-composable'
import {
  createMockClient as createMockedClient,
  type MockApolloClient,
  type RequestHandler,
} from 'mock-apollo-client'

import createCache from '#shared/server/apollo/cache.ts'
import type { CacheInitializerModules } from '#shared/types/server/apollo/client.ts'

import type { DocumentNode } from 'graphql'

const cacheInitializerModules: CacheInitializerModules = import.meta.glob(
  '../../mobile/server/apollo/cache/initializer/*.ts',
  { eager: true },
)

export interface ClientRequestHandler {
  operationDocument: DocumentNode
  handler: RequestHandler
}

let mockClient: Maybe<MockApolloClient>

afterEach(() => {
  mockClient = null
})

export const clearMockClient = () => {
  mockClient = null
}

const createMockClient = (handlers: ClientRequestHandler[]) => {
  if (!mockClient) {
    const cache = createCache(cacheInitializerModules)
    mockClient = createMockedClient({ cache })
    provideApolloClient(mockClient)
  }

  handlers.forEach((clientRequestHandler) =>
    mockClient?.setRequestHandler(
      clientRequestHandler.operationDocument,
      clientRequestHandler.handler,
    ),
  )

  return mockClient
}

export default createMockClient
