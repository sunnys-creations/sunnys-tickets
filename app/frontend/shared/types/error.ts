// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { UserError } from '#shared/graphql/types.ts'

import type { ApolloError } from '@apollo/client/core'
import type { Except } from 'type-fest'

export enum GraphQLErrorTypes {
  UnknownError = 'Exceptions::UnknownError',
  NetworkError = 'Exceptions::NetworkError',
  Forbidden = 'Exceptions::Forbidden',
  RecordNotFound = 'ActiveRecord::RecordNotFound',

  // This exception actually means 'NotAuthenticated'
  NotAuthorized = 'Exceptions::NotAuthorized',
}

export type GraphQLErrorTypeKeys = keyof GraphQLErrorTypes

export interface GraphQLErrorExtensionsHandler {
  type: GraphQLErrorTypes
  backtrace: string
}

export interface GraphQLHandlerError {
  type: GraphQLErrorTypes
  message?: string
}

export type MutationSendError = ApolloError | UserError

export enum ErrorStatusCodes {
  'Forbidden' = 403,
  'NotFound' = 404,
  'InternalError' = 500,
}

export type UserErrors = Except<UserError, '__typename'>[]
export interface UserFieldError {
  field: string
  message: string
}
export type UserFieldErrors = UserFieldError[]
