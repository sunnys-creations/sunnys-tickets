// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'

import { type FormFieldContext } from '../types/field.ts'

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const useValue = <T = any>(
  context: Ref<FormFieldContext<{ multiple?: boolean; clearValue?: unknown }>>,
) => {
  const currentValue = computed(() => context.value._value as T)

  const hasValue = computed(() => {
    return context.value.fns.hasValue(currentValue.value)
  })

  const valueContainer = computed<T[]>(() =>
    context.value.multiple ? (currentValue.value as T[]) : [currentValue.value],
  )

  const isCurrentValue = (value: T) => {
    if (!hasValue.value) return false
    return (valueContainer.value as unknown as T[]).includes(value)
  }

  const clearValue = (asyncSettling = true) => {
    if (!hasValue.value) return
    // if value is undefined, it is not sent to the backend
    // we want to clear the value, so we set it to null
    const clearValue =
      context.value.clearValue !== undefined ? context.value.clearValue : null
    context.value.node.input(clearValue, asyncSettling)
  }

  const localValue = computed({
    get: () => currentValue.value,
    set: (value) => {
      context.value.node.input(value)
    },
  })

  return {
    localValue,
    currentValue,
    hasValue,
    valueContainer,
    isCurrentValue,
    clearValue,
  }
}

export default useValue
