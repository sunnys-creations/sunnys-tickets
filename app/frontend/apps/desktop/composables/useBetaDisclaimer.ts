// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage } from '@vueuse/core'
import { storeToRefs } from 'pinia'
import { computed, h, nextTick, watch } from 'vue'
import { useRoute } from 'vue-router'

import { useAuthenticationStore } from '#shared/stores/authentication.ts'

import CommonDialog from '#desktop//components/CommonDialog/CommonDialog.vue'
import { useDialog } from '#desktop/components/CommonDialog/useDialog.ts'

export const useBetaDisclaimer = () => {
  const DIALOG_NAME = 'beta-ui-disclaimer'

  // In capybara the initial value should be true, to not have to close the dialog on every test run
  const hasDismissedWarning = useLocalStorage(
    'beta-ui-disclaimer',
    VITE_TEST_MODE,
  )
  const route = useRoute()
  const { authenticated } = storeToRefs(useAuthenticationStore())

  const afterAuthRouteActive = computed(
    // route.name is undefined when you visit or reload the after auth phase e.g two-factor auth
    () =>
      route.name === 'LoginAfterAuth' ||
      route.name === 'Login' ||
      route.name === undefined,
  )

  const dismissWarning = () => {
    hasDismissedWarning.value = true
  }

  const { open, close } = useDialog({
    name: DIALOG_NAME,
    fullscreen: true,
    component: () =>
      new Promise((resolve) => {
        resolve(
          h(CommonDialog, {
            wrapperTag: 'article',
            fullscreen: true,
            name: DIALOG_NAME,
            global: true,
            headerTitle: __('New Desktop UI — Alpha Version'),
            content: __(
              'This new desktop UI is currently in development and not ready for production use. It may contain bugs or incomplete features.',
            ),
            onClose: () => close().then(dismissWarning),
            footerActionOptions: {
              hideCancelButton: true,
              actionLabel: __('Confirm'),
            },
          }),
        )
      }),
  })

  const showDisclaimerWarning = () =>
    nextTick(() => {
      open()
    })

  watch(
    [afterAuthRouteActive, authenticated],
    ([afterAuth, isAuthenticated]) => {
      if (hasDismissedWarning.value || afterAuth || !isAuthenticated) return

      showDisclaimerWarning()
    },
  )
}
