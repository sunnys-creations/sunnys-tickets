// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import { autoCompleteProps } from '../FieldAutoComplete/index.ts'

import FieldAgentWrapper from './FieldAgentWrapper.vue'

const fieldDefinition = createInput(
  FieldAgentWrapper,
  [...autoCompleteProps, 'exceptUserInternalId'],
  {
    features: [addLink, formUpdaterTrigger()],
  },
)

export default {
  fieldType: 'agent',
  definition: fieldDefinition,
}
