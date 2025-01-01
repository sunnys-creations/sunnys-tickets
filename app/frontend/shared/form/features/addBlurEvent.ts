// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'

const addBlurEvent = (node: FormKitNode) => {
  node.on('created', () => {
    if (!node.context) return

    const originalBlurHandler = node.context.handlers.blur as (
      e?: FocusEvent,
    ) => void

    node.context.handlers.blur = (event?: FocusEvent) => {
      node.emit('blur', node.context?.value)
      // if node was not destroyed
      if (node.context) {
        originalBlurHandler(event)
      }
    }
  })
}

export default addBlurEvent
