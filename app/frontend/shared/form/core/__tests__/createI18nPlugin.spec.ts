// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import createI18nPlugin from '#shared/form/core/createI18nPlugin.ts'

describe('createI18nPlugin', () => {
  it('check that i18n plugin will be returned', () => {
    const i18Plugin = createI18nPlugin()

    expect(typeof i18Plugin).toEqual('function')
  })
})
