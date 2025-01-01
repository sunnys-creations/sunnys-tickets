// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { useNow } from '@vueuse/core'

const reactiveNow = useNow({
  interval: 1000,
})

export const useReactiveNow = () => reactiveNow
