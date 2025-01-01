// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { ref, type Ref, watch } from 'vue'

import { useReactiveNow } from '#shared/composables/useReactiveNow.ts'

import type { TicketLiveAppUser } from '../types.ts'

// Default idle time from 5 minutes.
const IDLE_TIME_MS = 5 * 60 * 1000

export const useTicketLiveUsersDisplay = (
  liveUserList: Ref<TicketLiveAppUser[]>,
) => {
  const liveUsers = ref<TicketLiveAppUser[]>([])
  const viewingUsers = ref<TicketLiveAppUser[]>([])
  const idleUsers = ref<TicketLiveAppUser[]>([])

  const reactiveNow = useReactiveNow()

  watch(
    [liveUserList, reactiveNow],
    () => {
      const localLiveUsers: TicketLiveAppUser[] = []

      liveUserList.value?.forEach((liveUser) => {
        if (
          new Date(liveUser.lastInteraction).getTime() + IDLE_TIME_MS <
          reactiveNow.value.getTime()
        ) {
          localLiveUsers.push({
            ...liveUser,
            isIdle: true,
          })
        } else {
          localLiveUsers.push({
            ...liveUser,
            isIdle: false,
          })
        }
      })

      liveUsers.value = localLiveUsers
      viewingUsers.value = localLiveUsers.filter((user) => !user.isIdle)
      idleUsers.value = localLiveUsers.filter((user) => user.isIdle)
    },
    { immediate: true },
  )

  return {
    liveUsers,
    viewingUsers,
    idleUsers,
  }
}
