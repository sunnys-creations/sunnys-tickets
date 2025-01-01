// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { cloneDeep } from 'lodash-es'

import {
  getByIconName,
  queryByIconName,
} from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import type {
  ExtendedMountingOptions,
  ExtendedRenderResult,
} from '#tests/support/components/index.ts'
import { mockGraphQLApi } from '#tests/support/mock-graphql-api.ts'
import { waitForNextTick, waitUntil } from '#tests/support/utils.ts'

import Form from '#shared/components/Form/Form.vue'
import type { Props } from '#shared/components/Form/Form.vue'
import { ObjectManagerFrontendAttributesDocument } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.api.ts'
import frontendObjectAttributes from '#shared/entities/ticket/__tests__/mocks/frontendObjectAttributes.json'
import {
  EnumFormUpdaterId,
  EnumObjectManagerObjects,
  type ObjectManagerScreenAttributes,
  type ObjectManagerFrontendAttributesPayload,
  type FormUpdaterQuery,
} from '#shared/graphql/types.ts'

import { FormUpdaterDocument } from '../../../graphql/queries/formUpdater.api.ts'
import additionalFrontendObjectAttributes from '../../mocks/additionalFrontendObjectAttributes.json'

import type { FormSchemaField, FormValues } from '../../../types.ts'

beforeAll(async () => {
  // so we don't need to wait until it loads inside test
  await import(
    // Could be changed, when mobile is longer the default app and we have a shared treeselect?
    // eslint-disable-next-line import/no-restricted-paths
    '#mobile/components/Form/fields/FieldTreeSelect/FieldTreeSelectInputDialog.vue'
  )
})

const wrapperParameters = {
  form: true,
  dialog: true,
  attachTo: document.body,
}

const mergeFrontendObjectAttributes = (
  mainObjectAttributes: ObjectManagerFrontendAttributesPayload,
  additionalObjectAttributes: ObjectManagerFrontendAttributesPayload,
) => {
  const localMainObjectAttributes = cloneDeep(mainObjectAttributes)
  const localAdditionalObjectAttributes = cloneDeep(additionalObjectAttributes)

  const attributes = localMainObjectAttributes.attributes.concat(
    localAdditionalObjectAttributes.attributes,
  )

  const additionalObjectAttriutesScreenLookup =
    localAdditionalObjectAttributes.screens.reduce(
      (screenLookup: Record<string, string[]>, screenItem) => {
        screenLookup[screenItem.name] = screenItem.attributes

        return screenLookup
      },
      {},
    )
  const screens: ObjectManagerScreenAttributes[] = []

  localMainObjectAttributes.screens.forEach((screenItem) => {
    screenItem.attributes = screenItem.attributes.concat(
      additionalObjectAttriutesScreenLookup[screenItem.name],
    )

    screens.push(screenItem)
  })

  return {
    attributes,
    screens,
  }
}

const getOuterFieldElement = (wrapper: ExtendedRenderResult, label: string) => {
  return wrapper.getByLabelText(label).closest('.formkit-outer')
}

const checkFieldHidden = (
  wrapper: ExtendedRenderResult,
  label: string,
  hidden: boolean,
) => {
  const outer = getOuterFieldElement(wrapper, label)

  if (hidden) {
    expect(outer).toHaveClass('hidden')
  } else {
    expect(outer).not.toHaveClass('hidden')
  }
}

const checkFieldRequired = (
  wrapper: ExtendedRenderResult,
  label: string,
  required: boolean,
) => {
  const outer = getOuterFieldElement(wrapper, label)

  if (required) {
    expect(outer).toHaveAttribute('data-required')
  } else {
    expect(outer).not.toHaveAttribute('data-required')
  }
}

const checkFieldDirty = (
  wrapper: ExtendedRenderResult,
  label: string,
  dirty: boolean,
) => {
  const outer = getOuterFieldElement(wrapper, label)

  if (dirty) {
    expect(outer).toHaveAttribute('data-dirty')
  } else {
    expect(outer).not.toHaveAttribute('data-dirty')
  }
}

const checkFieldDisabled = (
  wrapper: ExtendedRenderResult,
  label: string,
  disabled: boolean,
) => {
  const outer = getOuterFieldElement(wrapper, label)

  if (disabled) {
    expect(outer).toHaveAttribute('data-disabled')
  } else {
    expect(outer).not.toHaveAttribute('data-disabled')
  }
}

const checkDisplayValue = (
  wrapper: ExtendedRenderResult,
  label: string,
  value: string | string[],
) => {
  if (Array.isArray(value)) {
    value.forEach((valueItem) => {
      expect(wrapper.getByLabelText(label)).toHaveTextContent(valueItem)
    })
  } else {
    expect(wrapper.getByLabelText(label)).toHaveTextContent(value)
  }
}

const checkInputValue = (
  wrapper: ExtendedRenderResult,
  label: string,
  value: string | number,
) => {
  expect(wrapper.getByLabelText(label)).toHaveValue(value)
}

const checkSelected = (
  wrapper: ExtendedRenderResult,
  label: string,
  selected: boolean,
) => {
  if (selected) {
    expect(wrapper.getByLabelText(label)).toBeChecked()
  } else {
    expect(wrapper.getByLabelText(label)).not.toBeChecked()
  }
}

// Currently only the first level of a treeselect.
const checkSelectOptions = async (
  wrapper: ExtendedRenderResult,
  label: string,
  options: string[],
) => {
  await wrapper.events.click(wrapper.getByLabelText(label))

  const selectOptions = wrapper.getAllByRole('option')

  expect(selectOptions).toHaveLength(options.length)

  selectOptions.forEach((selectOption, index) => {
    expect(selectOption).toHaveTextContent(options[index])
  })

  // Treeselect dialog needs to be closed again.
  const doneButton = wrapper.queryByRole('button', { name: 'Done' })
  if (doneButton) {
    await wrapper.events.click(doneButton)
  }
}

const selectValue = async (
  wrapper: ExtendedRenderResult,
  label: string,
  dsiaplyValue: string,
) => {
  await wrapper.events.click(wrapper.getByLabelText(label))

  wrapper.events.click(wrapper.getByText(dsiaplyValue))

  await waitFor(() => {
    expect(wrapper.emitted().changed).toBeTruthy()
  })
}

const checkSelectClearable = (
  wrapper: ExtendedRenderResult,
  label: string,
  clearable: boolean,
  selectNewValue?: string,
) => {
  if (selectNewValue) {
    selectValue(wrapper, label, selectNewValue)
  }

  if (clearable) {
    expect(
      getByIconName(wrapper.getByLabelText(label), 'close-small'),
    ).toBeInTheDocument()
  } else {
    expect(
      queryByIconName(wrapper.getByLabelText(label), 'close-small'),
    ).not.toBeInTheDocument()
  }
}

const mergedObjectAttributes = mergeFrontendObjectAttributes(
  frontendObjectAttributes,
  additionalFrontendObjectAttributes,
)

const renderForm = async (
  formUpdaterQueryResponse: FormUpdaterQuery | FormUpdaterQuery[],
  options: ExtendedMountingOptions<Props> = {},
  objectManagerFrontendAttributes = mergedObjectAttributes,
) => {
  mockGraphQLApi(ObjectManagerFrontendAttributesDocument).willResolve({
    objectManagerFrontendAttributes,
  })

  const mockFormUpdaterApi = mockGraphQLApi(FormUpdaterDocument).willResolve(
    formUpdaterQueryResponse,
  )

  const wrapper = renderComponent(Form, {
    ...wrapperParameters,
    ...options,
    props: {
      useObjectAttributes: true,
      schema: [
        {
          object: EnumObjectManagerObjects.Ticket,
          name: 'title',
        },
        {
          object: EnumObjectManagerObjects.Ticket,
          screen: 'create_middle',
        },
        {
          type: 'submit',
          name: 'submit',
        },
      ],
      formUpdaterId: EnumFormUpdaterId.FormUpdaterUpdaterTicketCreate,
      ...(options.props || {}),
    },
  })

  await waitUntil(() => wrapper.emitted().settled)

  return {
    wrapper,
    mockFormUpdaterApi,
  }
}

describe('Form.vue - Form Updater - Initialization', () => {
  test('render initial form schema with select and treeselect fields', async () => {
    const { wrapper } = await renderForm({
      formUpdater: {
        fields: {
          group_id: {
            show: true,
            options: [
              {
                label: 'Users',
                value: 1,
              },
            ],
            clearable: false,
          },
          state_id: {
            show: true,
            options: [
              {
                label: 'new',
                value: 1,
              },
              {
                label: 'open',
                value: 2,
              },
            ],
            clearable: true,
          },
          type: {
            show: true,
            options: [
              {
                label: 'Problem',
                value: 'Problem',
              },
              {
                label: 'Request for Change',
                value: 'Request for Change',
              },
            ],
            value: 'Problem',
            clearable: true,
          },
          treeselect: {
            show: true,
            options: [
              {
                label: 'Incident',
                value: 'Incident',
              },
              {
                label: 'Service request',
                value: 'Service request',
              },
            ],
            value: 'Incident',
            clearable: true,
          },
          multitreeselect: {
            show: true,
            options: [
              {
                label: 'Incident',
                value: 'Incident',
              },
              {
                label: 'Service request',
                value: 'Service request',
              },
            ],
          },
          shared: {
            show: true,
            options: [
              {
                label: 'No',
                value: false,
              },
              {
                label: 'Yes',
                value: true,
              },
            ],
          },
        },
        flags: {},
      },
    })

    await checkSelectOptions(wrapper, 'Group', ['Users'])
    checkSelectClearable(wrapper, 'Group', false)
    await checkSelectOptions(wrapper, 'State', ['new', 'open'])
    checkSelectClearable(wrapper, 'State', true)

    checkDisplayValue(wrapper, 'Type', 'Problem')
    checkSelectClearable(wrapper, 'Type', true)

    await checkSelectOptions(wrapper, 'Type', ['Problem', 'Request for Change'])

    await checkSelectOptions(wrapper, 'Multi Select', [
      'Key 1',
      'Key 2',
      'Key 3',
      'Key 4',
    ])

    await checkSelectOptions(wrapper, 'Treeselect', [
      'Incident',
      'Service request',
    ])
    checkDisplayValue(wrapper, 'Treeselect', 'Incident')
    checkSelectClearable(wrapper, 'Treeselect', true)
  })

  test('render initial form schema with input, textarea, number, date, datetime', async () => {
    const { wrapper } = await renderForm({
      formUpdater: {
        fields: {
          title: {
            show: false,
          },
          textarea: {
            show: true,
            value: 'Example description',
          },
          example: {
            show: true,
            required: true,
          },
          number: {
            show: true,
            value: 10,
          },
        },
        flags: {},
      },
    })

    expect(wrapper.queryByLabelText('Title')).not.toBeInTheDocument()

    expect(wrapper.getByLabelText('Textarea')).toHaveValue(
      'Example description',
    )

    expect(wrapper.getByLabelText('Number')).toHaveValue(10)

    checkFieldRequired(wrapper, 'Example', true)

    expect(wrapper.getByLabelText('Date Time')).toBeInTheDocument()
    expect(wrapper.getByLabelText('Start Date')).toBeInTheDocument()
  })
})

describe('Form.vue - Form Updater - reacts on form updater results', () => {
  const formFields = {
    type: 'Type',
    multiselect: 'Multi Select',
    treeselect: 'Treeselect',
    multitreeselect: 'Multi Treeselect',
    example: 'Example',
    textarea: 'Textarea',
    number: 'Number',
    date_time: 'Date Time',
    start_date: 'Start Date',
    shared: 'Shared',
  }

  test('remove field after new form updater result comes in', async () => {
    const { wrapper, mockFormUpdaterApi } = await renderForm([
      {
        formUpdater: {
          fields: Object.keys(formFields).reduce(
            (
              showFields: Record<string, Partial<FormSchemaField>>,
              fieldName,
            ) => {
              showFields[fieldName] = {
                show: true,
              }
              return showFields
            },
            {},
          ),
          flags: {},
        },
      },
      {
        formUpdater: {
          fields: Object.keys(formFields).reduce(
            (
              removeFields: Record<string, Partial<FormSchemaField>>,
              fieldName,
            ) => {
              removeFields[fieldName] = {
                show: false,
              }
              return removeFields
            },
            {},
          ),
          flags: {},
        },
      },
    ])

    Object.values(formFields).forEach((fieldLabel) => {
      expect(wrapper.getByLabelText(fieldLabel)).toBeInTheDocument()
    })

    await selectValue(wrapper, 'Type', 'Incident')

    await waitUntil(() => mockFormUpdaterApi.calls.resolve === 2)

    Object.values(formFields).forEach((fieldLabel) => {
      expect(wrapper.queryByLabelText(fieldLabel)).not.toBeInTheDocument()
    })
  })

  test('show field after new form updater result comes in (from remove)', async () => {
    const { wrapper, mockFormUpdaterApi } = await renderForm([
      {
        formUpdater: {
          fields: {
            ...Object.keys(formFields).reduce(
              (
                removeFields: Record<string, Partial<FormSchemaField>>,
                fieldName,
              ) => {
                removeFields[fieldName] = {
                  show: false,
                }
                return removeFields
              },
              {},
            ),
            state_id: {
              show: true,
              options: [
                {
                  label: 'new',
                  value: 1,
                },
                {
                  label: 'open',
                  value: 2,
                },
              ],
              value: 1,
            },
          },
          flags: {},
        },
      },
      {
        formUpdater: {
          fields: Object.keys(formFields).reduce(
            (
              showFields: Record<string, Partial<FormSchemaField>>,
              fieldName,
            ) => {
              showFields[fieldName] = {
                show: true,
              }
              return showFields
            },
            {},
          ),
          flags: {},
        },
      },
    ])

    Object.values(formFields).forEach((fieldLabel) => {
      expect(wrapper.queryByLabelText(fieldLabel)).not.toBeInTheDocument()
    })

    await selectValue(wrapper, 'State', 'open')

    await waitUntil(() => mockFormUpdaterApi.calls.resolve === 2)

    Object.values(formFields).forEach((fieldLabel) => {
      expect(wrapper.getByLabelText(fieldLabel)).toBeInTheDocument()
    })
  })

  test('show field again with a new initial value', async () => {
    const { wrapper, mockFormUpdaterApi } = await renderForm([
      {
        formUpdater: {
          fields: {
            example: {
              show: false,
            },
          },
          flags: {},
        },
      },
      {
        formUpdater: {
          fields: {
            example: {
              show: true,
              value: 'A example text',
            },
          },
          flags: {},
        },
      },
    ])

    expect(wrapper.queryByLabelText('Example')).not.toBeInTheDocument()

    await selectValue(wrapper, 'Type', 'Incident')

    await waitUntil(() => mockFormUpdaterApi.calls.resolve === 2)

    const exampleField = wrapper.getByLabelText('Example')
    expect(exampleField).toBeInTheDocument()
    expect(exampleField).toHaveValue('A example text')
  })

  test('show field after new form updater result comes in (from hidden)', async () => {
    const { wrapper, mockFormUpdaterApi } = await renderForm([
      {
        formUpdater: {
          fields: {
            ...Object.keys(formFields).reduce(
              (
                hideFields: Record<string, Partial<FormSchemaField>>,
                fieldName,
              ) => {
                hideFields[fieldName] = {
                  show: true,
                  hidden: true,
                }
                return hideFields
              },
              {},
            ),
            state_id: {
              show: true,
              options: [
                {
                  label: 'new',
                  value: 1,
                },
                {
                  label: 'open',
                  value: 2,
                },
              ],
              value: 1,
            },
          },
          flags: {},
        },
      },
      {
        formUpdater: {
          fields: Object.keys(formFields).reduce(
            (
              showFields: Record<string, Partial<FormSchemaField>>,
              fieldName,
            ) => {
              showFields[fieldName] = {
                show: true,
                hidden: false,
              }
              return showFields
            },
            {},
          ),
          flags: {},
        },
      },
    ])

    Object.values(formFields).forEach((fieldLabel) => {
      expect(wrapper.getByLabelText(fieldLabel)).toBeInTheDocument()
      checkFieldHidden(wrapper, fieldLabel, true)
    })

    await selectValue(wrapper, 'State', 'open')

    await waitUntil(() => mockFormUpdaterApi.calls.resolve === 2)

    Object.values(formFields).forEach((fieldLabel) => {
      expect(wrapper.getByLabelText(fieldLabel)).toBeInTheDocument()
      checkFieldHidden(wrapper, fieldLabel, false)
    })
  })

  test('hide field after new form updater result comes in (from show)', async () => {
    const { wrapper, mockFormUpdaterApi } = await renderForm([
      {
        formUpdater: {
          fields: Object.keys(formFields).reduce(
            (
              showFields: Record<string, Partial<FormSchemaField>>,
              fieldName,
            ) => {
              showFields[fieldName] = {
                show: true,
                hidden: false,
              }
              return showFields
            },
            {},
          ),
          flags: {},
        },
      },
      {
        formUpdater: {
          fields: Object.keys(formFields).reduce(
            (
              hideFields: Record<string, Partial<FormSchemaField>>,
              fieldName,
            ) => {
              hideFields[fieldName] = {
                show: true,
                hidden: true,
              }
              return hideFields
            },
            {},
          ),
          flags: {},
        },
      },
    ])

    Object.values(formFields).forEach((fieldLabel) => {
      expect(wrapper.getByLabelText(fieldLabel)).toBeInTheDocument()
      checkFieldHidden(wrapper, fieldLabel, false)
    })

    await selectValue(wrapper, 'Type', 'Incident')

    await waitUntil(() => mockFormUpdaterApi.calls.resolve === 2)

    Object.values(formFields).forEach((fieldLabel) => {
      expect(wrapper.getByLabelText(fieldLabel)).toBeInTheDocument()
      checkFieldHidden(wrapper, fieldLabel, true)
    })
  })

  test('require field after new form updater result comes in (from not required)', async () => {
    const { wrapper, mockFormUpdaterApi } = await renderForm([
      {
        formUpdater: {
          fields: Object.keys(formFields).reduce(
            (
              notRequiredFields: Record<string, Partial<FormSchemaField>>,
              fieldName,
            ) => {
              notRequiredFields[fieldName] = {
                required: false,
              }
              return notRequiredFields
            },
            {},
          ),
          flags: {},
        },
      },
      {
        formUpdater: {
          fields: Object.keys(formFields).reduce(
            (
              requireFields: Record<string, Partial<FormSchemaField>>,
              fieldName,
            ) => {
              requireFields[fieldName] = {
                required: true,
              }
              return requireFields
            },
            {},
          ),
          flags: {},
        },
      },
    ])

    Object.values(formFields).forEach((fieldLabel) => {
      checkFieldRequired(wrapper, fieldLabel, false)
    })

    await selectValue(wrapper, 'Type', 'Incident')

    await waitUntil(() => mockFormUpdaterApi.calls.resolve === 2)

    Object.values(formFields).forEach((fieldLabel) => {
      checkFieldRequired(wrapper, fieldLabel, true)
    })
  })

  test('none require field after new form updater result comes in (from required)', async () => {
    const { wrapper, mockFormUpdaterApi } = await renderForm([
      {
        formUpdater: {
          fields: Object.keys(formFields).reduce(
            (
              requiredFields: Record<string, Partial<FormSchemaField>>,
              fieldName,
            ) => {
              requiredFields[fieldName] = {
                required: true,
              }
              return requiredFields
            },
            {},
          ),
          flags: {},
        },
      },
      {
        formUpdater: {
          fields: Object.keys(formFields).reduce(
            (
              notRequired: Record<string, Partial<FormSchemaField>>,
              fieldName,
            ) => {
              notRequired[fieldName] = {
                required: false,
              }
              return notRequired
            },
            {},
          ),
          flags: {},
        },
      },
    ])

    Object.values(formFields).forEach((fieldLabel) => {
      checkFieldRequired(wrapper, fieldLabel, true)
    })

    await selectValue(wrapper, 'Type', 'Incident')

    await waitUntil(() => mockFormUpdaterApi.calls.resolve === 2)

    Object.values(formFields).forEach((fieldLabel) => {
      checkFieldRequired(wrapper, fieldLabel, false)
    })
  })

  test('disable (readonly) field after new form updater result comes in (from not disabled)', async () => {
    const { wrapper, mockFormUpdaterApi } = await renderForm([
      {
        formUpdater: {
          fields: Object.keys(formFields).reduce(
            (
              notDisabledField: Record<string, Partial<FormSchemaField>>,
              fieldName,
            ) => {
              notDisabledField[fieldName] = {
                disabled: false,
              }
              return notDisabledField
            },
            {},
          ),
          flags: {},
        },
      },
      {
        formUpdater: {
          fields: Object.keys(formFields).reduce(
            (
              disableFields: Record<string, Partial<FormSchemaField>>,
              fieldName,
            ) => {
              disableFields[fieldName] = {
                disabled: true,
              }
              return disableFields
            },
            {},
          ),
          flags: {},
        },
      },
    ])

    Object.values(formFields).forEach((fieldLabel) => {
      checkFieldDisabled(wrapper, fieldLabel, false)
    })

    await selectValue(wrapper, 'Type', 'Incident')

    await waitUntil(() => mockFormUpdaterApi.calls.resolve === 2)

    Object.values(formFields).forEach((fieldLabel) => {
      checkFieldDisabled(wrapper, fieldLabel, true)
    })
  })

  test('not disabled (readonly) field after new form updater result comes in (from disabled)', async () => {
    const { wrapper, mockFormUpdaterApi } = await renderForm([
      {
        formUpdater: {
          fields: {
            ...Object.keys(formFields).reduce(
              (
                disabledField: Record<string, Partial<FormSchemaField>>,
                fieldName,
              ) => {
                disabledField[fieldName] = {
                  disabled: true,
                }
                return disabledField
              },
              {},
            ),
            state_id: {
              show: true,
              options: [
                {
                  label: 'new',
                  value: 1,
                },
                {
                  label: 'open',
                  value: 2,
                },
              ],
              value: 1,
            },
          },
          flags: {},
        },
      },
      {
        formUpdater: {
          fields: Object.keys(formFields).reduce(
            (
              notDisableFields: Record<string, Partial<FormSchemaField>>,
              fieldName,
            ) => {
              notDisableFields[fieldName] = {
                disabled: false,
              }
              return notDisableFields
            },
            {},
          ),
          flags: {},
        },
      },
    ])

    Object.values(formFields).forEach((fieldLabel) => {
      checkFieldDisabled(wrapper, fieldLabel, true)
    })

    await selectValue(wrapper, 'State', 'open')

    await waitUntil(() => mockFormUpdaterApi.calls.resolve === 2)

    Object.values(formFields).forEach((fieldLabel) => {
      checkFieldDisabled(wrapper, fieldLabel, false)
    })
  })

  test('set field value after new form updater result comes in', async () => {
    const { wrapper, mockFormUpdaterApi } = await renderForm([
      {
        formUpdater: {
          fields: {
            state_id: {
              show: true,
              options: [
                {
                  label: 'new',
                  value: 1,
                },
                {
                  label: 'open',
                  value: 2,
                },
              ],
              value: 1,
            },
          },
          flags: {},
        },
      },
      {
        formUpdater: {
          fields: {
            type: {
              value: 'Incident',
            },
            multiselect: {
              value: ['Key 1', 'Key 3'],
            },
            treeselect: {
              value: 'Service request',
            },
            multitreeselect: {
              value: ['Service request', 'Incident::Hardware'],
            },
            example: {
              value: 'example',
            },
            textarea: {
              value: 'some more text',
            },
            number: {
              value: 100,
            },
            shared: {
              value: true,
            },
          },
          flags: {},
        },
      },
    ])

    await selectValue(wrapper, 'State', 'open')

    await waitUntil(() => mockFormUpdaterApi.calls.resolve === 2)

    checkDisplayValue(wrapper, 'Type', 'Incident')
    checkDisplayValue(wrapper, 'Multi Select', ['Key 1', 'Key 3'])
    checkDisplayValue(wrapper, 'Treeselect', 'Service request')
    checkDisplayValue(wrapper, 'Multi Treeselect', [
      'Incident \u203A Hardware',
      'Service request',
    ])
    checkInputValue(wrapper, 'Example', 'example')
    checkInputValue(wrapper, 'Textarea', 'some more text')
    checkInputValue(wrapper, 'Number', 100)
    checkSelected(wrapper, 'Shared', true)
  })

  test('set field options after new form updater result comes in', async () => {
    const { wrapper, mockFormUpdaterApi } = await renderForm([
      {
        formUpdater: {
          fields: {},
          flags: {},
        },
      },
      {
        formUpdater: {
          fields: {
            multiselect: {
              options: [
                {
                  label: 'Key 1',
                  value: 'Key 1',
                },
                {
                  label: 'Key 4',
                  value: 'Key 4',
                },
              ],
            },
            multitreeselect: {
              options: [
                {
                  label: 'Service request',
                  value: 'Service request',
                  children: [
                    {
                      label: 'New hardware',
                      value: 'Service request::New hardware',
                    },
                  ],
                },
              ],
            },
          },
          flags: {},
        },
      },
    ])

    await checkSelectOptions(wrapper, 'Multi Select', [
      'Key 1',
      'Key 2',
      'Key 3',
      'Key 4',
    ])

    await checkSelectOptions(wrapper, 'Multi Treeselect', [
      'Incident',
      'Service request',
    ])

    await selectValue(wrapper, 'Type', 'Incident')

    await waitUntil(() => mockFormUpdaterApi.calls.resolve === 2)

    await checkSelectOptions(wrapper, 'Multi Select', ['Key 1', 'Key 4'])

    await checkSelectOptions(wrapper, 'Multi Treeselect', ['Service request'])
  })
})

describe('Form.vue - Form Updater - special situations', () => {
  test('show field again with a new initial value', async () => {
    const { wrapper, mockFormUpdaterApi } = await renderForm([
      {
        formUpdater: {
          fields: {
            example: {
              show: false,
            },
          },
          flags: {},
        },
      },
      {
        formUpdater: {
          fields: {
            example: {
              show: true,
              value: 'A example text',
            },
          },
          flags: {},
        },
      },
    ])

    expect(wrapper.queryByLabelText('Example')).not.toBeInTheDocument()

    await selectValue(wrapper, 'Type', 'Incident')

    await waitUntil(() => mockFormUpdaterApi.calls.resolve === 2)

    const exampleField = wrapper.getByLabelText('Example')
    expect(exampleField).toBeInTheDocument()
    expect(exampleField).toHaveValue('A example text')
  })

  test('change field value (should not trigger additional request)', async () => {
    const { wrapper, mockFormUpdaterApi } = await renderForm([
      {
        formUpdater: {
          fields: {
            state_id: {
              show: true,
              options: [
                {
                  label: 'new',
                  value: 1,
                },
                {
                  label: 'open',
                  value: 2,
                },
              ],
            },
          },
          flags: {},
        },
      },
      {
        formUpdater: {
          fields: {
            state_id: {
              show: true,
              options: [
                {
                  label: 'new',
                  value: 1,
                },
                {
                  label: 'open',
                  value: 2,
                },
              ],
              value: 2,
            },
          },
          flags: {},
        },
      },
    ])

    checkDisplayValue(wrapper, 'State', 'new')

    await selectValue(wrapper, 'Type', 'Incident')
    await waitUntil(() => mockFormUpdaterApi.calls.resolve === 2)

    checkDisplayValue(wrapper, 'State', 'open')
  })

  test('preselect first value when no longer clearable (should not trigger additional request)', async () => {
    const { wrapper, mockFormUpdaterApi } = await renderForm([
      {
        formUpdater: {
          fields: {
            state_id: {
              show: true,
              options: [
                {
                  label: 'new',
                  value: 1,
                },
                {
                  label: 'open',
                  value: 2,
                },
              ],
              value: '',
              clearable: true,
            },
          },
          flags: {},
        },
      },
      {
        formUpdater: {
          fields: {
            state_id: {
              show: true,
              options: [
                {
                  label: 'new',
                  value: 1,
                },
                {
                  label: 'open',
                  value: 2,
                },
              ],
              clearable: false,
            },
          },
          flags: {},
        },
      },
    ])

    checkDisplayValue(wrapper, 'State', '')

    await selectValue(wrapper, 'Type', 'Incident')
    await waitUntil(() => mockFormUpdaterApi.calls.resolve === 2)

    checkDisplayValue(wrapper, 'State', 'new')
  })

  test('delay submit and perform form updater request before', async () => {
    const submitCallbackSpy = vi.fn()

    const { wrapper, mockFormUpdaterApi } = await renderForm(
      [
        {
          formUpdater: {
            fields: {
              state_id: {
                options: [
                  {
                    label: 'new',
                    value: 1,
                  },
                  {
                    label: 'open',
                    value: 2,
                  },
                ],
              },
            },
            flags: {},
          },
        },
        {
          formUpdater: {
            fields: {
              textarea: {
                value: 'Some text',
              },
              group_id: {
                required: false,
              },
              state_id: {
                required: false,
              },
            },
            flags: {},
          },
        },
      ],
      {
        props: {
          onSubmit: (data: FormValues) => submitCallbackSpy(data),
        },
      },
    )

    const title = wrapper.getByLabelText('Title')
    await wrapper.events.type(title, 'Example title')
    await wrapper.events.type(title, '{Enter}')

    await waitUntil(() => mockFormUpdaterApi.calls.resolve === 2)

    await waitFor(() => {
      expect(submitCallbackSpy).toHaveBeenCalledWith({
        title: 'Example title',
        textarea: 'Some text',
        date_time: undefined,
        example: '',
        group_id: undefined,
        multiselect: [],
        multitreeselect: undefined,
        number: '',
        shared: false,
        start_date: undefined,
        state_id: 1,
        treeselect: undefined,
        type: undefined,
      })
    })
  })

  test('usage together with changeFields prop (fixed required field from frontend side)', async () => {
    const { wrapper, mockFormUpdaterApi } = await renderForm(
      [
        {
          formUpdater: {
            fields: {
              example: {
                required: false,
              },
            },
            flags: {},
          },
        },
        {
          formUpdater: {
            fields: {
              example: {
                required: false,
              },
            },
            flags: {},
          },
        },
      ],
      {
        props: {
          changeFields: {
            example: {
              required: true,
            },
          },
        },
      },
    )

    checkFieldRequired(wrapper, 'Example', true)

    await selectValue(wrapper, 'Type', 'Incident')
    await waitUntil(() => mockFormUpdaterApi.calls.resolve === 2)

    checkFieldRequired(wrapper, 'Example', true)
  })

  test('test dirty flag set for initialValues changes from form update', async () => {
    const { wrapper } = await renderForm(
      {
        formUpdater: {
          fields: {
            example: {
              value: 'changed',
            },
          },
          flags: {},
        },
      },
      {
        props: {
          initialValues: {
            example: 'test',
          },
        },
      },
    )

    checkFieldDirty(wrapper, 'Example', true)
  })

  test('test dirty flag unset for initialValues changes from form update', async () => {
    const { wrapper } = await renderForm(
      {
        formUpdater: {
          fields: {
            example: {
              value: 'test',
            },
          },
          flags: {},
        },
      },
      {
        props: {
          initialValues: {
            example: 'test',
          },
        },
      },
    )

    checkFieldDirty(wrapper, 'Example', false)
  })

  test('no endless loop (additional request) for non existing options for new field values', async () => {
    const { wrapper, mockFormUpdaterApi } = await renderForm(
      [
        {
          formUpdater: {
            fields: {},
            flags: {},
          },
        },
        {
          formUpdater: {
            fields: {
              multiselect: {
                options: [
                  {
                    label: 'Key 1',
                    value: 'Key 1',
                  },
                  {
                    label: 'Key 4',
                    value: 'Key 4',
                  },
                ],
                value: ['Key 1', 'Key 3'],
              },
            },
            flags: {},
          },
        },
      ],
      {
        props: {
          initialValues: {
            multiselect: ['Key 1', 'Key 2'],
          },
        },
      },
    )

    await waitUntil(() => {
      return mockFormUpdaterApi.calls.resolve === 1
    })

    await selectValue(wrapper, 'Type', 'Incident')
    await waitUntil(() => {
      return mockFormUpdaterApi.calls.resolve === 2
    })

    await waitForNextTick()

    await checkDisplayValue(wrapper, 'Multi Select', ['Key 1'])
  })

  test('no endless loop (additional request) for activated preselect mode in single select', async () => {
    const { wrapper, mockFormUpdaterApi } = await renderForm(
      [
        {
          formUpdater: {
            fields: {
              type: {
                options: [
                  {
                    label: 'Request for Change',
                    value: 'Request for Change',
                  },
                ],
                value: 'Problem',
                clearable: false,
                rejectNonExistentValues: true,
              },
            },
            flags: {},
          },
        },
      ],
      {
        props: {
          initialValues: {
            type: 'Incident',
          },
        },
      },
    )

    await waitUntil(() => {
      return mockFormUpdaterApi.calls.resolve === 1
    })

    await waitForNextTick()

    // Should show the initial value after the form is initialized.
    await checkDisplayValue(wrapper, 'Type', 'Request for Change')
  })

  test('add empty value for multiselect, when present in the current returned values', async () => {
    const { wrapper, mockFormUpdaterApi } = await renderForm(
      [
        {
          formUpdater: {
            fields: {},
            flags: {},
          },
        },
        {
          formUpdater: {
            fields: {
              multiselect: {
                options: [
                  {
                    label: 'Key 1',
                    value: 'Key 1',
                  },
                  {
                    label: 'Key 4',
                    value: 'Key 4',
                  },
                ],
                value: ['', 'Key 1', 'Key 4'],
              },
            },
            flags: {},
          },
        },
      ],
      {
        props: {
          initialValues: {
            multiselect: ['Key 1', 'Key 2'],
          },
        },
      },
    )

    await waitUntil(() => {
      return mockFormUpdaterApi.calls.resolve === 1
    })

    await selectValue(wrapper, 'Type', 'Incident')
    await waitUntil(() => {
      return mockFormUpdaterApi.calls.resolve === 2
    })

    await waitForNextTick()

    await checkSelectOptions(wrapper, 'Multi Select', ['Key 1', 'Key 4', '-'])
    await checkDisplayValue(wrapper, 'Multi Select', ['-', 'Key 1', 'Key 4'])
  })
})
