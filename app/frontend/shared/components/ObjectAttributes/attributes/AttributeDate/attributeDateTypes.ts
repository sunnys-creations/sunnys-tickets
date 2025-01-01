// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { ObjectManagerFrontendAttribute } from '#shared/graphql/types.ts'

export interface ObjectAttributeDate extends ObjectManagerFrontendAttribute {
  dataType: 'date' | 'datetime'
  dataOption: {
    relation: string
    null: boolean
    past?: boolean
    future?: boolean
    include_timezone?: boolean
    default: Maybe<string>
    diff: Maybe<number>
  }
}
