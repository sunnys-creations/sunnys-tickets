// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectManagerFrontendAttribute } from '#shared/graphql/types.ts'

export interface ObjectAttributeRichtext
  extends ObjectManagerFrontendAttribute {
  dataType: 'richtext'
  dataOption: {
    maxlength: number
    no_images: boolean
    note: string
    null: boolean
    upload?: boolean
    rows?: number
    type: string // text
  }
}
