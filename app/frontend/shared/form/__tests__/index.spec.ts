// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { createApp } from 'vue'

import type { ImportGlobEagerOutput } from '#shared/types/utils.ts'

import initializeForm, { getFormPlugins } from '../index.ts'

import type { FormKitPlugin } from '@formkit/core'

describe('getFormPlugins', () => {
  const examplePlugin = vi.fn()
  const pluginModules: ImportGlobEagerOutput<FormKitPlugin> = {
    'common/test/plugins/test.ts': {
      default: examplePlugin,
    },
    'common/test/plugins/example.ts': {
      default: examplePlugin,
    },
  }

  it('should return the plugin list', () => {
    expect(getFormPlugins(pluginModules)).toEqual([
      examplePlugin,
      examplePlugin,
    ])
  })
})

describe('initializeForm', () => {
  const app = createApp({})

  vi.spyOn(app, 'use')

  it('check use form plugin without an error', () => {
    initializeForm(app)

    expect(app.use).toHaveBeenCalled()
  })
})
