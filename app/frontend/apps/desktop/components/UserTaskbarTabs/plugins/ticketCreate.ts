// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { EnumTaskbarEntity } from '#shared/graphql/types.ts'
import type { ObjectWithUid } from '#shared/types/utils.ts'

import type { UserTaskbarTabPlugin } from '#desktop/components/UserTaskbarTabs/types.ts'

import TicketCreate from '../Ticket/TicketCreate.vue'

export default <UserTaskbarTabPlugin>{
  type: EnumTaskbarEntity.TicketCreate,
  component: TicketCreate,
  buildEntityTabKey: (entityInternalId: string) =>
    `TicketCreateScreen-${entityInternalId}`,
  buildTaskbarTabParams: (entityInternalId: string) => {
    return {
      id: entityInternalId,
    }
  },
  buildTaskbarTabLink: (entity?: ObjectWithUid) => {
    if (!entity?.uid) return
    return `/tickets/create/${entity.uid}`
  },
  confirmTabRemove: async (dirty?: boolean) => {
    if (!dirty) return true

    const { waitForVariantConfirmation } = useConfirmation()

    return waitForVariantConfirmation('unsaved')
  },
}
