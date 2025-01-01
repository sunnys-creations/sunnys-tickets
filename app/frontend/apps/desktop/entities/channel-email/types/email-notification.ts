// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { EmailOutboundData } from './email-inbound-outbound.ts'

export type EmailNotificationData = EmailOutboundData & {
  notification_sender: string
}
