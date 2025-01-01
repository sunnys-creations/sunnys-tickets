// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { getByText, waitFor } from '@testing-library/vue'
import { cloneDeep, escapeRegExp } from 'lodash-es'

import { getByIconName } from '#tests/support/components/iconQueries.ts'
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

import type { SelectValue } from '#shared/components/CommonSelect/types.ts'
import type { AutocompleteSearchUserQuery } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import { AutocompleteSearchUserDocument } from '../../../../../../../shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/user.api.ts'

const testOptions = [
  {
    value: 0,
    label: 'Item A',
    heading: 'autocomplete sample 1',
    user: nullableMock({
      id: 1,
      fullname: 'sample 1',
    }),
  },
  {
    value: 1,
    label: 'Item B',
    heading: 'autocomplete sample 2',
    user: nullableMock({
      id: 2,
      fullname: 'sample 2',
    }),
  },
  {
    value: 2,
    label: 'Ítem C',
    heading: 'autocomplete sample 3',
    user: nullableMock({
      id: 3,
      fullname: 'sample 3',
    }),
  },
]

const mockQueryResult = (input: {
  query: string
  limit: number
}): AutocompleteSearchUserQuery => {
  const options = testOptions.map((option) => ({
    ...option,
    labelPlaceholder: null,
    headingPlaceholder: null,
    disabled: null,
    icon: null,
    __typename: 'AutocompleteUserEntry',
  }))

  const deaccent = (s: string) =>
    s.normalize('NFD').replace(/[\u0300-\u036f]/g, '')

  // Trim and de-accent search keywords and compile them as a case-insensitive regex.
  //   Make sure to escape special regex characters!
  const filterRegex = new RegExp(escapeRegExp(deaccent(input.query)), 'i')

  // Search across options via their de-accented labels.
  const filteredOptions = options.filter((option) =>
    filterRegex.test(deaccent(option.label)),
  ) as unknown as AutocompleteSearchUserQuery['autocompleteSearchUser']

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
  label: 'Select…',
  type: 'autocomplete',
  gqlQuery: AutocompleteSearchUserDocument,
}

beforeAll(async () => {
  // So we don't need to wait until it loads inside test.
  await import('../FieldAutoCompleteInputDialog.vue')
})

describe('Form - Field - AutoComplete - Dialog', () => {
  it('renders select options in a modal dialog', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(testOptions.length)

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
      expect(selectOption).toHaveTextContent(testOptions[index].heading)
    })

    await wrapper.events.click(wrapper.getByRole('button', { name: /Done/ }))

    expect(wrapper.queryByRole('dialog')).not.toBeInTheDocument()
  })

  it('sets value on selection and closes the dialog', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    wrapper.events.click(wrapper.getAllByRole('option')[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(testOptions[0].value)

    expect(wrapper.queryByRole('dialog')).not.toBeInTheDocument()
  })

  it('renders selected option with a check mark icon', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        value: testOptions[1].value,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    expect(wrapper.getByIconName('check')).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByRole('button', { name: /Done/ }))

    expect(wrapper.queryByRole('dialog')).not.toBeInTheDocument()
  })
})

describe('Form - Field - AutoComplete - Query', () => {
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

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    expect(filterElement).toBeInTheDocument()

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()

    // Search is always case-insensitive.
    await wrapper.events.type(filterElement, 'a')

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    await waitUntil(() => mockApi.calls.behave)

    let selectOptions = wrapper.getAllByRole('option')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)

    await wrapper.events.click(wrapper.getByLabelText('Clear Search'))

    expect(filterElement).toHaveValue('')

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()

    // Search for non-accented characters matches items with accents too.
    await wrapper.events.type(filterElement, 'item c')

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[2].label)

    await wrapper.events.clear(filterElement)

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()

    // Search for accented characters matches items with accents too.
    await wrapper.events.type(filterElement, 'ítem c')

    expect(
      wrapper.queryByText('Start typing to search…'),
    ).not.toBeInTheDocument()

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[2].label)
  })

  it('replaces local options with selection', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    await wrapper.events.type(filterElement, 'a')

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

  it('restores selection on clearing search input (multiple)', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        value: [testOptions[2].value],
        options: [testOptions[2]],
        multiple: true,
        debounceInterval: 0,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    let selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[2].label)
    expect(getByIconName(selectOptions[0], 'check-box-yes')).toBeInTheDocument()

    const filterElement = wrapper.getByRole('searchbox')

    await wrapper.events.type(filterElement, 'item')

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(3)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)
    expect(selectOptions[1]).toHaveTextContent(testOptions[1].label)
    expect(selectOptions[2]).toHaveTextContent(testOptions[2].label)
    expect(getByIconName(selectOptions[2], 'check-box-yes')).toBeInTheDocument()

    wrapper.events.click(selectOptions[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toStrictEqual([
      testOptions[0].value,
      testOptions[2].value,
    ])

    await wrapper.events.click(wrapper.getByLabelText('Clear Search'))

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(2)
    expect(selectOptions[0]).toHaveTextContent(testOptions[2].label)
    expect(getByIconName(selectOptions[0], 'check-box-yes')).toBeInTheDocument()
    expect(selectOptions[1]).toHaveTextContent(testOptions[0].label)
    expect(getByIconName(selectOptions[1], 'check-box-yes')).toBeInTheDocument()
  })

  it('supports storing complex non-multiple values', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        name: 'autocomplete',
        id: 'autocomplete',
        complexValue: true,
        debounceInterval: 0,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    expect(filterElement).toBeInTheDocument()

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()

    // Search is always case-insensitive.
    await wrapper.events.type(filterElement, 'a')
    const selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)

    await wrapper.events.click(selectOptions[0])

    const node = getNode('autocomplete')
    expect(node?._value).toEqual({
      value: testOptions[0].value,
      label: testOptions[0].label,
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[0].label,
    )
  })

  it('supports storing complex multiple values', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        name: 'autocomplete',
        id: 'autocomplete',
        multiple: true,
        complexValue: true,
        debounceInterval: 0,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    expect(filterElement).toBeInTheDocument()

    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()

    await wrapper.events.type(filterElement, 'item')
    const selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(3)
    expect(selectOptions[0]).toHaveTextContent(testOptions[0].label)
    expect(selectOptions[1]).toHaveTextContent(testOptions[1].label)
    expect(selectOptions[2]).toHaveTextContent(testOptions[2].label)

    await wrapper.events.click(selectOptions[0])
    await wrapper.events.click(selectOptions[1])

    await wrapper.events.click(wrapper.getByRole('button', { name: /Done/ }))

    const [item1, item2] = wrapper.getAllByRole('listitem')

    expect(item1).toHaveTextContent(testOptions[0].label)
    expect(item2).toHaveTextContent(testOptions[1].label)

    const node = getNode('autocomplete')
    expect(node?._value).toEqual([
      {
        value: testOptions[0].value,
        label: testOptions[0].label,
      },
      {
        value: testOptions[1].value,
        label: testOptions[1].label,
      },
    ])
  })
})

describe('Form - Field - AutoComplete - Initial Options', () => {
  it('supports disabled property', async () => {
    const disabledOptions = [
      {
        value: 0,
        label: 'Item A',
      },
      {
        value: 1,
        label: 'Item B',
        disabled: true,
      },
      {
        value: 2,
        label: 'Item C',
      },
    ]

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: disabledOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    expect(wrapper.getAllByRole('option')[1]).toHaveClass('pointer-events-none')

    expect(
      getByText(wrapper.getByRole('listbox'), disabledOptions[1].label),
    ).toHaveClass('opacity-30')
  })

  it('supports icon property', async () => {
    const iconOptions = [
      {
        value: 1,
        label: 'GitLab',
        icon: 'gitlab',
      },
      {
        value: 2,
        label: 'GitHub',
        icon: 'github',
      },
    ]

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: iconOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    expect(wrapper.queryByIconName(iconOptions[0].icon)).toBeInTheDocument()
    expect(wrapper.queryByIconName(iconOptions[1].icon)).toBeInTheDocument()
  })
})

describe('Form - Field - AutoComplete - Features', () => {
  it('supports value mutation', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        id: 'autocomplete',
        options: testOptions,
        value: testOptions[1].value,
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[1].label,
    )

    const node = getNode('autocomplete')
    node?.input(testOptions[2].value)

    await waitForNextTick(true)

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[2].label,
    )
  })

  it('supports selection clearing', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        value: testOptions[1].value,
        clearable: true,
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[1].label,
    )

    await wrapper.events.click(wrapper.getByRole('button'))

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(null)

    expect(wrapper.queryByRole('listitem')).not.toBeInTheDocument()
    expect(wrapper.queryByRole('button')).not.toBeInTheDocument()
  })

  it('supports custom clear value', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        value: testOptions[1].value,
        clearable: true,
        clearValue: {},
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      testOptions[1].label,
    )

    await wrapper.events.click(wrapper.getByRole('button'))

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toEqual({})

    expect(wrapper.queryByRole('listitem')).not.toBeInTheDocument()
    expect(wrapper.queryByRole('button')).not.toBeInTheDocument()
  })

  it('supports multiple selection', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        multiple: true,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(
      wrapper.queryAllByIconName('check-box-no').length,
    )

    wrapper.events.click(selectOptions[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toStrictEqual([testOptions[0].value])
    expect(wrapper.queryAllByIconName('check-box-no')).toHaveLength(2)
    expect(wrapper.queryAllByIconName('check-box-yes')).toHaveLength(1)
    expect(wrapper.queryByRole('dialog')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(1)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label)
    })

    wrapper.events.click(selectOptions[1])

    await waitFor(() => {
      expect(emittedInput[1][0]).toStrictEqual([
        testOptions[0].value,
        testOptions[1].value,
      ])
    })

    expect(wrapper.queryAllByIconName('check-box-no')).toHaveLength(1)
    expect(wrapper.queryAllByIconName('check-box-yes')).toHaveLength(2)
    expect(wrapper.queryByRole('dialog')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(2)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label)
    })

    wrapper.events.click(selectOptions[2])

    await waitFor(() => {
      expect(emittedInput[2][0]).toStrictEqual([
        testOptions[0].value,
        testOptions[1].value,
        testOptions[2].value,
      ])
    })

    expect(wrapper.queryAllByIconName('check-box-no')).toHaveLength(0)
    expect(wrapper.queryAllByIconName('check-box-yes')).toHaveLength(3)
    expect(wrapper.queryByRole('dialog')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(3)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label)
    })

    wrapper.events.click(selectOptions[2])

    await waitFor(() => {
      expect(emittedInput[3][0]).toStrictEqual([
        testOptions[0].value,
        testOptions[1].value,
      ])
    })

    expect(wrapper.queryAllByIconName('check-box-no')).toHaveLength(1)
    expect(wrapper.queryAllByIconName('check-box-yes')).toHaveLength(2)
    expect(wrapper.queryByRole('dialog')).toBeInTheDocument()
    expect(wrapper.queryAllByRole('listitem')).toHaveLength(2)

    wrapper.queryAllByRole('listitem').forEach((selectedLabel, index) => {
      expect(selectedLabel).toHaveTextContent(testOptions[index].label)
    })

    await wrapper.events.click(wrapper.getByRole('button'))
  })

  it('supports option sorting', async (context) => {
    context.skipConsole = true

    const reversedOptions = cloneDeep(testOptions).reverse()

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: reversedOptions,
        sorting: 'label',
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    let selectOptions = wrapper.getAllByRole('option')

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
    })

    await wrapper.rerender({
      sorting: 'value',
    })

    selectOptions = wrapper.getAllByRole('option')

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(testOptions[index].label)
    })

    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {
      // no-op, silence warnings on the console
    })

    await wrapper.rerender({
      sorting: 'foobar',
    })

    expect(warn).toHaveBeenCalledWith('Unsupported sorting option "foobar"')
  })

  it('supports label translation', async () => {
    const untranslatedOptions = [
      {
        value: 0,
        label: 'Item A (%s)',
        labelPlaceholder: [0],
        heading: 'autocomplete sample %s',
        headingPlaceholder: [1],
      },
      {
        value: 1,
        label: 'Item B (%s)',
        labelPlaceholder: [1],
        heading: 'autocomplete sample %s',
        headingPlaceholder: [2],
      },
      {
        value: 2,
        label: 'Item C (%s)',
        heading: 'autocomplete sample',
      },
    ]

    i18n.setTranslationMap(
      new Map([
        ['Item C', 'Translated Item C'],
        ['autocomplete sample', 'translated autocomplete sample'],
      ]),
    )

    const translatedOptions = untranslatedOptions.map((untranslatedOption) => ({
      ...untranslatedOption,
      label: i18n.t(
        untranslatedOption.label,
        untranslatedOption.labelPlaceholder as never,
      ),
      heading: i18n.t(
        untranslatedOption.heading,
        untranslatedOption.headingPlaceholder as never,
      ),
    }))

    let wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: untranslatedOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    let selectOptions = wrapper.getAllByRole('option')

    selectOptions.forEach((selectOption, index) => {
      expect(selectOption).toHaveTextContent(translatedOptions[index].label)
      expect(selectOption).toHaveTextContent(translatedOptions[index].heading)
    })

    await wrapper.events.click(selectOptions[0])

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      translatedOptions[0].label,
    )

    wrapper.unmount()

    wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: untranslatedOptions,
        noOptionsLabelTranslation: true,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    selectOptions = wrapper.getAllByRole('option')

    selectOptions.forEach((selectOption, index) => {
      // Forces translation due to placeholder availability.
      if (untranslatedOptions[index].labelPlaceholder) {
        expect(selectOption).toHaveTextContent(translatedOptions[index].heading)
        expect(selectOption).toHaveTextContent(translatedOptions[index].label)
      } else {
        expect(selectOption).toHaveTextContent(
          untranslatedOptions[index].heading,
        )
        expect(selectOption).toHaveTextContent(untranslatedOptions[index].label)
      }
    })

    await wrapper.events.click(selectOptions[2])

    expect(wrapper.getByRole('listitem')).toHaveTextContent(
      untranslatedOptions[2].label,
    )
  })

  it('supports additional action', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        action: '/route',
        actionIcon: 'web',
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    expect(wrapper.getByIconName('web')).toBeInTheDocument()
  })

  it('supports selection of unknown values', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        allowUnknownValues: true,
        debounceInterval: 0,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    await wrapper.events.type(filterElement, 'Item D')

    let selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent('Item D')

    wrapper.events.click(wrapper.getAllByRole('option')[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe('Item D')
    expect(wrapper.getByRole('listitem')).toHaveTextContent('Item D')

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent('Item D')
  })

  it('supports validation of filter input', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        allowUnknownValues: true,
        debounceInterval: 0,
        filterInputValidation: 'starts_with:#',
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    await wrapper.events.type(filterElement, 'foo')

    expect(
      wrapper.queryByText(`This field doesn't start with "#".`),
    ).toBeInTheDocument()

    expect(wrapper.queryByText('No results found')).toBeInTheDocument()

    await wrapper.events.clear(filterElement)

    await wrapper.events.type(filterElement, '#foo')

    expect(
      wrapper.queryByText(`This field doesn't start with "#".`),
    ).not.toBeInTheDocument()

    const selectOptions = await wrapper.findAllByRole('option')

    expect(selectOptions).toHaveLength(1)
    expect(selectOptions[0]).toHaveTextContent('#foo')
  })

  it('supports value prefill with initial option builder', () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        value: 1234,
        initialOptionBuilder: (object: ObjectLike, value: SelectValue) => {
          return {
            value,
            label: `Item ${value}`,
          }
        },
      },
    })

    expect(wrapper.getByRole('listitem')).toHaveTextContent(`Item 1234`)
  })

  describe('supports complex values', () => {
    it('supports non-multiple complex value', () => {
      const wrapper = renderComponent(FormKit, {
        ...wrapperParameters,
        props: {
          ...testProps,
          value: {
            value: 1234,
            label: 'Item 1234',
          },
        },
      })

      expect(wrapper.getByRole('listitem')).toHaveTextContent('Item 1234')
    })
  })

  it('supports multiple complex value', () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        multiple: true,
        value: [
          {
            value: 1234,
            label: 'Item 1234',
          },
          {
            value: 4321,
            label: 'Item 4321',
          },
        ],
      },
    })

    const [item1, item2] = wrapper.getAllByRole('listitem')

    expect(item1).toHaveTextContent('Item 1234')
    expect(item2).toHaveTextContent('Item 4321')
  })
})

describe('Form - Field - AutoComplete - Accessibility', () => {
  it('supports element focusing', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        clearable: true,
        value: testOptions[0].value,
      },
    })

    expect(wrapper.getByLabelText('Select…')).toHaveAttribute('tabindex', '0')

    expect(wrapper.getByRole('button')).toHaveAttribute('tabindex', '0')

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    const selectOptions = wrapper.getAllByRole('option')

    expect(selectOptions).toHaveLength(testOptions.length)

    selectOptions.forEach((selectOption) => {
      expect(selectOption).toHaveAttribute('tabindex', '0')
    })
  })

  it('allows focusing of disabled field for a11y', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        disabled: true,
      },
    })

    expect(wrapper.getByLabelText('Select…')).toHaveAttribute('tabindex', '0')
  })

  it("clicking disabled field doesn't select dialog", async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        disabled: true,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    expect(wrapper.queryByRole('dialog')).not.toBeInTheDocument()
  })

  it('clicking select without options still opens select dialog', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: [],
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    expect(wrapper.queryByRole('dialog')).toBeInTheDocument()
  })

  it('provides labels for screen readers', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        clearable: true,
        value: testOptions[1].value,
      },
    })

    expect(wrapper.getByRole('button')).toHaveAttribute(
      'aria-label',
      'Clear Selection',
    )
  })

  it('supports keyboard navigation', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        clearable: true,
        value: testOptions[1].value,
      },
    })

    await wrapper.events.type(wrapper.getByLabelText('Select…'), '{Space}')

    const selectOptions = wrapper.getAllByRole('option')

    wrapper.events.type(selectOptions[0], '{Space}')

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(testOptions[0].value)

    wrapper.events.type(wrapper.getByRole('button'), '{Space}')

    await waitFor(() => {
      expect(emittedInput[1][0]).toBe(null)
    })
  })

  it('restores focus on close', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        clearable: true,
        value: testOptions[1].value,
      },
    })

    const selectButton = wrapper.getByLabelText('Select…')

    await wrapper.events.click(selectButton)

    expect(selectButton).not.toHaveFocus()

    const selectOptions = wrapper.getAllByRole('option')

    await wrapper.events.type(selectOptions[0], '{Space}')

    expect(selectButton).toHaveFocus()
  })
})

// Cover all use cases from the FormKit custom input checklist.
//   More info here: https://formkit.com/advanced/custom-inputs#input-checklist
describe('Form - Field - AutoComplete - Input Checklist', () => {
  it('implements input id attribute', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        id: 'test_id',
        options: testOptions,
      },
    })

    expect(wrapper.getByLabelText('Select…')).toHaveAttribute('id', 'test_id')
  })

  it('implements input name', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        name: 'test_name',
        options: testOptions,
      },
    })

    expect(wrapper.getByLabelText('Select…')).toHaveAttribute(
      'name',
      'test_name',
    )
  })

  it('implements blur handler', async () => {
    const blurHandler = vi.fn()

    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        onBlur: blurHandler,
      },
    })

    wrapper.getByLabelText('Select…').focus()
    await wrapper.events.tab()

    expect(blurHandler).toHaveBeenCalledOnce()
  })

  it('implements input handler', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
      },
    })

    await wrapper.events.click(wrapper.getByLabelText('Select…'))

    wrapper.events.click(wrapper.getAllByRole('option')[1])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(testOptions[1].value)
  })

  it.each([0, 1, 2])(
    'implements input value display',
    async (testOptionsIndex) => {
      const testOption = testOptions[testOptionsIndex]

      const wrapper = renderComponent(FormKit, {
        ...wrapperParameters,
        props: {
          ...testProps,
          options: testOptions,
          value: testOption.value,
        },
      })

      expect(wrapper.getByRole('listitem')).toHaveTextContent(testOption.label)
    },
  )

  it('implements disabled', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        disabled: true,
      },
    })

    expect(wrapper.getByLabelText('Select…')).toHaveClass(
      'formkit-disabled:pointer-events-none',
    )
  })

  it('implements attribute passthrough', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
        'test-attribute': 'test_value',
      },
    })

    expect(wrapper.getByLabelText('Select…')).toHaveAttribute(
      'test-attribute',
      'test_value',
    )
  })

  it('implements standardized classes', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        options: testOptions,
      },
    })

    expect(wrapper.getByTestId('field-autocomplete')).toHaveClass(
      'formkit-input',
    )
  })
})
