// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { getByTestId, waitFor } from '@testing-library/vue'
import { escapeRegExp } from 'lodash-es'

import { renderComponent } from '#tests/support/components/index.ts'
import {
  mockGraphQLApi,
  type MockGraphQLInstance,
} from '#tests/support/mock-graphql-api.ts'
import {
  nullableMock,
  waitForNextTick,
  waitUntil,
} from '#tests/support/utils.ts'

import { AutocompleteSearchUserDocument } from '#shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/user.api.ts'
import type {
  AutocompleteSearchUserQuery,
  AutocompleteSearchUserEntry,
} from '#shared/graphql/types.ts'

import testOptions from './test-options.json'

const mockQueryResult = (input: {
  query: string
  limit: number
}): AutocompleteSearchUserQuery => {
  const options = testOptions.map((option) =>
    nullableMock({
      ...option,
      labelPlaceholder: null,
      headingPlaceholder: null,
      disabled: null,
      icon: null,
      __typename: 'AutocompleteSearchUserEntry',
    }),
  )

  const deaccent = (s: string) =>
    s.normalize('NFD').replace(/[\u0300-\u036f]/g, '')

  // Trim and de-accent search keywords and compile them as a case-insensitive regex.
  //   Make sure to escape special regex characters!
  const filterRegex = new RegExp(escapeRegExp(deaccent(input.query)), 'i')

  // Search across options via their de-accented labels.
  const filteredOptions = options.filter(
    (option) =>
      filterRegex.test(deaccent(option.label)) ||
      filterRegex.test(deaccent(option.heading)),
  ) as unknown as AutocompleteSearchUserEntry[]

  return {
    autocompleteSearchUser: filteredOptions.slice(0, input.limit ?? 25),
  }
}

const wrapperParameters = {
  form: true,
  formField: true,
  router: true,
  dialog: true,
  store: true,
}

const testProps = {
  type: 'customer',
  label: 'Select…',
}

beforeAll(async () => {
  // So we don't need to wait until it loads inside test.
  await import('../../FieldAutoComplete/FieldAutoCompleteInputDialog.vue')
})

describe('Form - Field - Customer - Features', () => {
  it('supports value prefill with existing entity object in root node', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        id: 'customer',
        name: 'customer_id',
        value: 123,
        belongsToObjectField: 'customer',
      },
    })

    const node = getNode('customer')
    node!.context!.initialEntityObject = {
      customer: {
        internalId: 123,
        fullname: 'John Doe',
      },
    }

    await waitForNextTick(true)

    expect(wrapper.getByRole('listitem')).toHaveTextContent(`John Doe`)
  })
})

describe('Form - Field - Customer - Query', () => {
  let mockApi: MockGraphQLInstance

  beforeEach(() => {
    mockApi = mockGraphQLApi(AutocompleteSearchUserDocument).willBehave(
      (variables) => {
        return {
          data: mockQueryResult(variables.input),
        }
      },
    )
  })

  it('fetches remote options via GraphQL query', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
      },
    })

    await wrapper.events.click(await wrapper.findByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    expect(filterElement).toBeInTheDocument()

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()

    // Search is always case-insensitive.
    await wrapper.events.type(filterElement, 'adam')

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    let selectOptions = wrapper.getAllByRole('option')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].heading)

    // User with ID 1 should show the logo.
    expect(getByTestId(selectOptions[0], 'common-avatar')).toHaveStyle({
      'background-image': `url(${testOptions[0].user.image})`,
    })

    await wrapper.events.click(wrapper.getByLabelText('Clear Search'))

    expect(filterElement).toHaveValue('')

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()

    // Search for non-accented characters matches items with accents too.
    await wrapper.events.type(filterElement, 'rodríguez')

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    await waitUntil(() => mockApi.calls.behave)

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[1].label)
    expect(selectOptions[0]).toHaveTextContent(testOptions[1].heading)

    expect(getByTestId(selectOptions[0], 'common-avatar')).toHaveStyle({
      'background-image': `url(${testOptions[1].user.image})`,
    })

    await wrapper.events.clear(filterElement)

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()

    // Search for accented characters matches items with accents too.
    await wrapper.events.type(filterElement, 'rodríguez')

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[1].label)
    expect(selectOptions[0]).toHaveTextContent(testOptions[1].heading)

    expect(getByTestId(selectOptions[0], 'common-avatar')).toHaveStyle({
      'background-image': `url(${testOptions[1].user.image})`,
    })
  })

  it('replaces local options with selection', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
      },
    })

    await wrapper.events.click(await wrapper.findByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    await wrapper.events.type(filterElement, 'adam')

    wrapper.events.click(wrapper.getAllByRole('option')[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(testOptions[0].value)

    expect(wrapper.queryByRole('dialog')).not.toBeInTheDocument()

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[0].label,
    )

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    expect(wrapper.getByIconName('check')).toBeInTheDocument()
  })
})
