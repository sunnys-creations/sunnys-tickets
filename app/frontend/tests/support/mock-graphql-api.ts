// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/
/* eslint-disable no-use-before-define */

import { NetworkStatus } from '@apollo/client/core'
import {
  createMockSubscription,
  type IMockSubscription,
  type RequestHandlerResponse,
} from 'mock-apollo-client'

import type { UserError } from '#shared/graphql/types.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import createMockClient from './mock-apollo-client.ts'
import { waitForNextTick } from './utils.ts'

import type { DocumentNode, GraphQLFormattedError } from 'graphql'
import type { MockInstance } from 'vitest'

interface Result {
  [key: string]: unknown
}

interface ResultWithUserError extends Result {
  errors: UserError[]
}

type OperationResultWithUserError = Record<string, ResultWithUserError>

export interface MockGraphQLInstance {
  willBehave<T>(handler: (variables: any) => T): MockGraphQLInstance
  willResolve<T>(result: T): MockGraphQLInstance
  willFailWithError(
    errors: GraphQLFormattedError[],
    networkStatus?: NetworkStatus,
  ): MockGraphQLInstance
  willFailWithUserError(
    result: OperationResultWithUserError,
  ): MockGraphQLInstance
  willFailWithForbiddenError(message?: string): MockGraphQLInstance
  willFailWithNotFoundError(message?: string): MockGraphQLInstance
  willFailWithNetworkError(error: Error): MockGraphQLInstance
  spies: {
    behave: MockInstance
    resolve: MockInstance
    error: MockInstance
    userError: MockInstance
    networkError: MockInstance
  }
  calls: {
    behave: number
    resolve: number
    error: number
    userError: number
    networkError: number
  }
}

export const mockGraphQLApi = (
  operationDocument: DocumentNode,
): MockGraphQLInstance => {
  const resolveSpy = vi.fn()
  const errorSpy = vi.fn()
  const userErrorSpy = vi.fn()
  const networkErrorSpy = vi.fn()
  const behaveSpy = vi.fn()

  const willBehave = (fn: (variables: any) => unknown) => {
    behaveSpy.mockImplementation(async (variables: any) => fn(variables))
    createMockClient([
      {
        operationDocument,
        handler: behaveSpy,
      },
    ])
    return instance
  }

  const willResolve = <T>(result: T | T[]) => {
    if (Array.isArray(result)) {
      result.forEach((singleResult) => {
        resolveSpy.mockResolvedValueOnce({ data: singleResult })
      })
    } else {
      resolveSpy.mockResolvedValue({ data: result })
    }
    createMockClient([
      {
        operationDocument,
        handler: resolveSpy,
      },
    ])
    return instance
  }

  const willFailWithError = (
    errors: GraphQLFormattedError[],
    networkStatus?: NetworkStatus,
  ) => {
    errorSpy.mockResolvedValue({
      networkStatus: networkStatus || NetworkStatus.error,
      errors,
    })
    createMockClient([
      {
        operationDocument,
        handler: errorSpy,
      },
    ])
    return instance
  }

  const willFailWithNotFoundError = (message = 'Not Found') => {
    errorSpy.mockResolvedValue({
      networkStatus: NetworkStatus.error,
      errors: [
        {
          extensions: {
            type: GraphQLErrorTypes.RecordNotFound,
          },
          message,
        },
      ],
    })
    createMockClient([
      {
        operationDocument,
        handler: errorSpy,
      },
    ])
    return instance
  }

  const willFailWithForbiddenError = (message = 'Forbidden') => {
    errorSpy.mockResolvedValue({
      networkStatus: NetworkStatus.error,
      errors: [
        {
          extensions: {
            type: GraphQLErrorTypes.Forbidden,
          },
          message,
        },
      ],
    })
    createMockClient([
      {
        operationDocument,
        handler: errorSpy,
      },
    ])
    return instance
  }

  const willFailWithUserError = (result: OperationResultWithUserError) => {
    userErrorSpy.mockResolvedValue({ data: result })
    createMockClient([
      {
        operationDocument,
        handler: userErrorSpy,
      },
    ])
    return instance
  }

  const willFailWithNetworkError = (error: Error) => {
    networkErrorSpy.mockRejectedValue(error)
    createMockClient([
      {
        operationDocument,
        handler: networkErrorSpy,
      },
    ])
    return instance
  }

  const instance = {
    willFailWithError,
    willFailWithUserError,
    willFailWithNotFoundError,
    willFailWithForbiddenError,
    willFailWithNetworkError,
    willResolve,
    willBehave,
    spies: {
      behave: behaveSpy,
      resolve: resolveSpy,
      error: errorSpy,
      userError: userErrorSpy,
      networkError: networkErrorSpy,
    },
    calls: {
      get behave() {
        return behaveSpy.mock.calls.length
      },
      get resolve() {
        return resolveSpy.mock.calls.length
      },
      get error() {
        return errorSpy.mock.calls.length
      },
      get userError() {
        return userErrorSpy.mock.calls.length
      },
      get networkError() {
        return networkErrorSpy.mock.calls.length
      },
    },
  }

  return instance
}

export interface ExtendedIMockSubscription<T = unknown>
  extends Omit<IMockSubscription, 'next' | 'closed'> {
  closed: () => boolean
  next: (result: RequestHandlerResponse<T>) => Promise<void>
}

export const mockGraphQLSubscription = <T>(
  operationDocument: DocumentNode,
): ExtendedIMockSubscription<T> => {
  const mockSubscription = createMockSubscription({ disableLogging: true })

  createMockClient([
    {
      operationDocument,
      handler: () => mockSubscription,
    },
  ])

  return {
    next: async (
      value: Parameters<typeof mockSubscription.next>[0],
    ): Promise<void> => {
      mockSubscription.next(value)

      await waitForNextTick(true)
    },
    error: mockSubscription.error.bind(mockSubscription),
    complete: mockSubscription.complete.bind(mockSubscription),
    closed: () => mockSubscription.closed,
  }
}
