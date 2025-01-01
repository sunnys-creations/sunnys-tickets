// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { SetOptional } from 'type-fest'

export enum NotificationTypes {
  Warn = 'warn',
  Success = 'success',
  Error = 'error',
  Info = 'info',
}

export type NotificationClass =
  | NotificationTypes
  | 'base'
  | 'baseContainer'
  | 'message'
export type NotificationClassMap = Record<NotificationClass, string>

export interface Notification {
  id: string
  message: string
  /**
   * Should notification be shown only once.
   * Multiple invocations with same ID will remove the previous notification.
   */
  unique?: boolean
  messagePlaceholder?: string[]
  type: NotificationTypes
  durationMS?: number
  persistent?: boolean
  callback?: () => void
  /**
   * @private
   */
  timeout: number
}

export type NewNotification = SetOptional<Notification, 'id' | 'timeout'>
