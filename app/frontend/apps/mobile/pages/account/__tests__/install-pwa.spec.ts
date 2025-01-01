// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { visitView } from '#tests/support/components/visitView.ts'

import * as utilsBrowser from '#shared/utils/browser.ts'
import * as utilsPWA from '#shared/utils/pwa.ts'

import type { Mock } from 'vitest'

const utilsPWAmock = vi.mocked(utilsPWA)
const utilsBrowsermock = vi.mocked(utilsBrowser)

vi.mock('#shared/utils/browser.ts')
vi.mock('#shared/utils/pwa.ts')

const mockPWA = ({
  canInstallPWA = false,
  isStandalone = false,
  installPWA = vi.fn(),
}: {
  canInstallPWA?: boolean
  isStandalone?: boolean
  installPWA?: Mock
}) => {
  utilsPWAmock.usePWASupport.mockReturnValue({
    canInstallPWA: computed(() => canInstallPWA),
    installPWA,
  })
  vi.spyOn(utilsPWA, 'isStandalone').mockReturnValue(isStandalone)
}

describe('Installing Zammad as PWA', () => {
  test("cannot install zammad as PWA, so user doesn't see a button", async () => {
    mockPWA({ canInstallPWA: false, isStandalone: false })

    const view = await visitView('/account')

    expect(view.queryByText('Install')).not.toBeInTheDocument()
  })
  test("already opened as PWA, so user doesn't see a button", async () => {
    mockPWA({ canInstallPWA: false, isStandalone: true })

    const view = await visitView('/account')

    expect(view.queryByText('Install')).not.toBeInTheDocument()
  })

  test('installing PWA, when prompt event is available', async () => {
    const installPWA = vi.fn()
    mockPWA({ canInstallPWA: true, isStandalone: false, installPWA })

    const view = await visitView('/account')

    const install = view.getByText('Install App')

    await view.events.click(install)

    expect(installPWA).toHaveBeenCalled()
  })

  test('installing PWA on iOS - show instructions', async () => {
    utilsBrowsermock.browser.name = 'Safari'
    utilsBrowsermock.os.name = 'iOS'
    mockPWA({ canInstallPWA: false, isStandalone: false })

    const view = await visitView('/account')

    const install = view.getByText('Install App')

    await view.events.click(install)

    expect(
      view.getByText(/To install Zammad as an app, press/),
    ).toBeInTheDocument()
    expect(view.getByIconName('ios-share')).toBeInTheDocument()
    expect(view.getByIconName('add-square')).toBeInTheDocument()
  })
})
