// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import type { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

import { useObjectAttributes } from './useObjectAttributes.ts'

export const useObjectAttributeLoadFormFields = (
  objectAttributeObjects: EnumObjectManagerObjects[],
) => {
  const objectAttributesByObject: Partial<
    Record<EnumObjectManagerObjects, ReturnType<typeof useObjectAttributes>>
  > = {}

  objectAttributeObjects.forEach((object) => {
    objectAttributesByObject[object] = useObjectAttributes(object)
  })

  const objectAttributesLoading = computed(() => {
    let loading = false

    const usedObjects = Object.keys(
      objectAttributesByObject,
    ) as EnumObjectManagerObjects[]

    usedObjects.forEach((object: EnumObjectManagerObjects) => {
      if (
        (
          objectAttributesByObject[object] as ReturnType<
            typeof useObjectAttributes
          >
        ).formFieldAttributesLookup.value.size === 0
      ) {
        loading = true
      }
    })

    return loading
  })

  return {
    objectAttributesLoading,
  }
}
