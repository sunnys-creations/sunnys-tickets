// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { FormHandlerExecution } from '#shared/components/Form/types.ts'
import type {
  FormSchemaField,
  ReactiveFormSchemData,
  ChangedField,
  FormHandlerFunction,
  FormHandler,
} from '#shared/components/Form/types.ts'
import { getAutoCompleteOption } from '#shared/entities/organization/utils/getAutoCompleteOption.ts'
import type { Organization, Scalars } from '#shared/graphql/types.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type { UserData } from '#shared/types/store.ts' // TODO: remove this import

// TODO: needs to be aligned, when auto completes has a final state.
export const useTicketFormOrganizationHandler = (): FormHandler => {
  const executeHandler = (
    execution: FormHandlerExecution,
    schemaData: ReactiveFormSchemData,
    changedField?: ChangedField,
  ) => {
    if (!schemaData.fields.organization_id) return false
    if (
      execution === FormHandlerExecution.FieldChange &&
      (!changedField || changedField.name !== 'customer_id')
    ) {
      return false
    }

    return true
  }

  const handleOrganizationField: FormHandlerFunction = (
    execution,
    reactivity,
    data,
    // eslint-disable-next-line sonarjs/cognitive-complexity
  ) => {
    const { formNode, values, initialEntityObject, changedField } = data
    const { schemaData, changeFields, updateSchemaDataField } = reactivity

    if (!executeHandler(execution, schemaData, changedField)) return

    const session = useSessionStore()

    const organizationField: Partial<FormSchemaField> = {
      show: false,
      required: false,
    }

    const setCustomer = (): Maybe<UserData> | undefined => {
      if (session.hasPermission('ticket.agent')) {
        if (changedField?.newValue) {
          // TODO: user <=> object ?!?!?
          const optionValue = formNode?.find('customer_id', 'name')?.context
            ?.optionValueLookup as Record<
            number,
            Record<'object' | 'user', UserData>
          >
          // ⚠️ :INFO mobile query retrieves .user and .object for desktop
          return (
            (optionValue[changedField.newValue as number].object as UserData) ||
            (optionValue[changedField.newValue as number].user as UserData)
          )
        }

        if (
          execution === FormHandlerExecution.FieldChange ||
          !values.customer_id ||
          !initialEntityObject
        )
          return undefined

        return initialEntityObject.customer
      }

      return session.user
    }

    const setOrganizationField = (
      customerId: Scalars['ID']['output'],
      organization?: Maybe<Partial<Organization>>,
    ) => {
      if (!organization) return

      organizationField.show = true
      organizationField.required = true

      const currentValueOption = getAutoCompleteOption(organization)

      // Some information can be changed during the next user interactions, so update only the current schema data.
      updateSchemaDataField({
        name: 'organization_id',
        props: {
          defaultFilter: '*',
          alwaysApplyDefaultFilter: true,
          options: [currentValueOption],
          additionalQueryParams: {
            customerId,
          },
        },
        value: currentValueOption.value,
      })
    }

    const customer = setCustomer()
    if (customer?.hasSecondaryOrganizations) {
      setOrganizationField(
        customer.id,
        execution === FormHandlerExecution.Initial && initialEntityObject
          ? initialEntityObject.organization
          : (customer.organization as Organization),
      )
    }

    // This values should be fixed, until the user change something in the customer_id field.
    changeFields.value.organization_id = {
      ...(changeFields.value.organization_id || {}),
      ...organizationField,
    }
  }

  return {
    execution: [FormHandlerExecution.Initial, FormHandlerExecution.FieldChange],
    callback: handleOrganizationField,
  }
}
