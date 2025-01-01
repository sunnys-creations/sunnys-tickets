// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { ViewTransitions } from '#mobile/components/transition/TransitionViewNavigation/types.ts'
import { useViewTransition } from '#mobile/components/transition/TransitionViewNavigation/useViewTransition.ts'

import type {
  NavigationGuard,
  RouteLocationNormalized,
  NavigationGuardNext,
} from 'vue-router'

const transitionViewGuard: NavigationGuard = (
  to: RouteLocationNormalized,
  from: RouteLocationNormalized,
  next: NavigationGuardNext,
) => {
  // For now we need to add a workaround solution with a route level for the different transition types
  // until the following feature was added: https://github.com/vuejs/vue-router/issues/3453.
  const { setViewTransition } = useViewTransition()

  let newViewTransition: ViewTransitions = ViewTransitions.Replace

  // In the case that the 'To'-Route has no level, we use the replace transition.
  if (to.meta?.level) {
    const previousLevel = from.meta?.level || 1

    if (previousLevel !== to.meta.level) {
      newViewTransition =
        previousLevel < to.meta.level
          ? ViewTransitions.Next
          : ViewTransitions.Prev
    }
  }

  setViewTransition(newViewTransition)

  next()
}

export default transitionViewGuard
