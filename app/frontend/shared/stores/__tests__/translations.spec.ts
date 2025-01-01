// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { provideApolloClient } from '@vue/apollo-composable'
import { createMockClient } from 'mock-apollo-client'
import { createPinia, setActivePinia } from 'pinia'

import { TranslationsDocument } from '#shared/graphql/queries/translations.api.ts'
import type { TranslationsPayload } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'

import { useTranslationsStore } from '../translations.ts'

const mockQueryResult = (
  locale: string,
  cacheKey: string | null,
): TranslationsPayload => {
  if (cacheKey === 'MOCKED_CACHE_KEY') {
    return {
      isCacheStillValid: true,
      cacheKey,
      translations: {},
    }
  }
  if (locale === 'de-de') {
    return {
      isCacheStillValid: false,
      cacheKey: 'MOCKED_CACHE_KEY',
      translations: {
        Login: 'Anmeldung',
      },
    }
  }
  return {
    isCacheStillValid: false,
    cacheKey: 'MOCKED_CACHE_KEY',
    translations: {
      Login: 'Login (translated)',
    },
  }
}

let lastQueryResult: TranslationsPayload

const mockClient = () => {
  const mockApolloClient = createMockClient()

  mockApolloClient.setRequestHandler(TranslationsDocument, (variables) => {
    lastQueryResult = mockQueryResult(variables.locale, variables.cacheKey)

    return Promise.resolve({ data: { translations: lastQueryResult } })
  })

  provideApolloClient(mockApolloClient)
}

describe('Translations Store', () => {
  setActivePinia(createPinia())
  const translations = useTranslationsStore()
  mockClient()

  it('is empty by default', () => {
    expect(translations.cacheKey).toBe('CACHE_EMPTY')
    expect(translations.translationData).toStrictEqual({})
    expect(i18n.t('Login')).toBe('Login')
  })

  it('loads translations without cache', async () => {
    expect.assertions(4)
    await translations.load('de-de')
    expect(lastQueryResult.isCacheStillValid).toBe(false)
    expect(translations.cacheKey.length).toBeGreaterThan(5)
    expect(translations.translationData).toHaveProperty('Login', 'Anmeldung')
    expect(i18n.t('Login')).toBe('Anmeldung')
  })

  it('switch to en-us translations', async () => {
    expect.assertions(3)
    await translations.load('en-us')
    expect(lastQueryResult.isCacheStillValid).toBe(false)
    expect(translations.cacheKey.length).toBeGreaterThan(5)
    expect(translations.translationData).toHaveProperty(
      'Login',
      'Login (translated)',
    )
  })

  it('loads translations from a warm cache', async () => {
    expect.assertions(5)
    await translations.load('de-de')
    expect(lastQueryResult.isCacheStillValid).toBe(true)
    expect(lastQueryResult.translations).toStrictEqual({})
    expect(translations.cacheKey.length).toBeGreaterThan(5)
    expect(translations.translationData).toHaveProperty('Login', 'Anmeldung')
    expect(i18n.t('Login')).toBe('Anmeldung')
  })
})
