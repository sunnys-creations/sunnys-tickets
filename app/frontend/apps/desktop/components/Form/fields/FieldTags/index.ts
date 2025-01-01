// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import { autoCompleteProps } from '../FieldAutoComplete/index.ts'

import FieldTagsWrapper from './FieldTagsWrapper.vue'

const fieldDefinition = createInput(
  FieldTagsWrapper,
  [...autoCompleteProps, 'canCreate', 'exclude', 'onDeactivate'],
  {
    features: [addLink, formUpdaterTrigger()],
  },
)

export default {
  fieldType: 'tags',
  definition: fieldDefinition,
}
