// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectManagerFrontendAttribute } from '#shared/graphql/types.ts'

export interface ObjectAttributeTextarea
  extends ObjectManagerFrontendAttribute {
  dataType: 'textarea'
  dataOption: {
    item_class: string
    maxlength: number
    linktemplate?: string
    null: boolean
  }
}
