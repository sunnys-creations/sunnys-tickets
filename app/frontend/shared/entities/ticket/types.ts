// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { FileUploaded } from '#shared/components/Form/fields/FieldFile/types.ts'
import type { SecurityValue } from '#shared/components/Form/fields/FieldSecurity/types.ts'
import type { FormFieldValue } from '#shared/components/Form/types.ts'
import type {
  TicketQuery,
  TicketArticlesQuery,
  TicketLiveUser,
  EnumTaskbarApp,
  EnumSecurityOption,
} from '#shared/graphql/types.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

export enum TicketState {
  Closed = 'closed',
  WaitingForClosure = 'pending close',
  WaitingForReminder = 'pending reminder',
  Open = 'open',
  New = 'new',
}

export enum TicketCreateArticleType {
  PhoneIn = 'phone-in',
  PhoneOut = 'phone-out',
  EmailOut = 'email-out',
}

export type TicketView = 'agent' | 'customer'

export interface TicketLiveAppUser {
  user: TicketLiveUser['user']
  editing: boolean
  lastInteraction: string
  app: EnumTaskbarApp
  isIdle?: boolean
}

export type TicketById = TicketQuery['ticket']

export type TicketArticle = ConfidentTake<
  TicketArticlesQuery,
  'articles.edges.node'
>

export interface TicketCustomerUpdateFormData {
  customer_id: number
  organization_id?: number
}

export interface TicketFormData {
  title: string
  customer_id?: number
  cc?: string[]
  body: string
  attachments?: FileUploaded[]
  group_id: number
  owner_id?: number
  state_id?: number
  pending_time?: string
  priority_id?: number
  articleSenderType: TicketCreateArticleType
  tags: string[]
  security?: EnumSecurityOption[]
  [index: string]: FormFieldValue
}

export interface TicketUpdateFormData {
  group_id: number
  owner_id?: number
  state_id?: number
  priority_id?: number
  pending_time?: string
  isDefaultFollowUpStateSet?: boolean
  article?: {
    articleType?: string
    body?: string
    internal?: boolean
    cc?: string[]
    subtype?: string
    inReplyTo?: string
    to?: string[]
    subject?: string
    contentType?: string
    security?: SecurityValue
    timeUnit?: number
    accountedTimeTypeId?: ID
  }
  [index: string]: FormFieldValue
}

export interface TicketArticleTimeAccountingFormData {
  time_unit?: string
  accounted_time_type_id?: number
}

export type TicketDuplicateDetectionItem = [
  id: number,
  number: string,
  title: string,
]
