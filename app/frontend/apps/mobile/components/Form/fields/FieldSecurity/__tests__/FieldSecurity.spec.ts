// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'

import { renderComponent } from '#tests/support/components/index.ts'

import { EnumSecurityStateType } from '#shared/components/Form/fields/FieldSecurity/types.ts'
import Form from '#shared/components/Form/Form.vue'

const renderSecurityField = (props: any = {}) => {
  return renderComponent(FormKit, {
    form: true,
    formField: true,
    props: {
      id: 'security',
      type: 'security',
      name: 'security',
      label: 'Security',
      ...props,
    },
  })
}

describe('FieldSecurity', () => {
  it('renders both buttons to choose from if there are several', async () => {
    const view = renderSecurityField({
      securityAllowed: {
        [EnumSecurityStateType.Pgp]: ['encryption', 'sign'],
        [EnumSecurityStateType.Smime]: ['encryption', 'sign'],
      },
      securityDefaultOptions: {
        [EnumSecurityStateType.Pgp]: ['encryption', 'sign'],
        [EnumSecurityStateType.Smime]: ['encryption', 'sign'],
      },
    })

    const node = getNode('security')!

    const pgp = view.getByRole('option', { name: 'PGP' })
    const smime = view.getByRole('option', { name: 'S/MIME' })

    expect(pgp).toBeInTheDocument()
    expect(pgp).not.toBeDisabled()
    expect(pgp).not.toHaveAttribute('aria-selected', 'true')

    expect(smime).toBeInTheDocument()
    expect(smime).not.toBeDisabled()
    expect(smime, 'smime is enabled by default').toHaveAttribute(
      'aria-selected',
      'true',
    )

    const encrypt = view.getByRole('option', { name: 'Encrypt' })
    await view.events.click(encrypt)

    expect(encrypt).toHaveAttribute('aria-selected', 'true')
    expect(smime).toHaveAttribute('aria-selected', 'true')

    expect(node.context?._value).toEqual({
      method: EnumSecurityStateType.Smime,
      options: ['encryption'],
    })

    await view.events.click(pgp)

    expect(encrypt).toHaveAttribute('aria-selected', 'true')
    expect(smime).not.toHaveAttribute('aria-selected', 'true')
    expect(pgp).toHaveAttribute('aria-selected', 'true')

    expect(node.context?._value).toEqual({
      method: EnumSecurityStateType.Pgp,
      options: ['encryption', 'sign'],
    })
  })

  it('removing options dynamically resets the value', async () => {
    const view = renderSecurityField({
      securityAllowed: {
        [EnumSecurityStateType.Pgp]: ['encryption', 'sign'],
        [EnumSecurityStateType.Smime]: ['encryption', 'sign'],
      },
    })

    const node = getNode('security')!

    expect(node.context?._value).toBe(undefined)

    const encrypt = view.getByRole('option', { name: 'Encrypt' })
    await view.events.click(encrypt)

    expect(node.context?._value).toEqual({
      method: EnumSecurityStateType.Smime,
      options: ['encryption'],
    })
  })

  it('pgp is default if smime is not available', async () => {
    const view = renderSecurityField({
      securityAllowed: {
        [EnumSecurityStateType.Pgp]: ['encryption', 'sign'],
      },
    })

    expect(
      view.queryByRole('option', { name: 'S/MIME' }),
    ).not.toBeInTheDocument()
    expect(view.queryByRole('option', { name: 'PGP' })).not.toBeInTheDocument()

    const encrypt = view.getByRole('option', { name: 'Encrypt' })
    await view.events.click(encrypt)

    expect(getNode('security')?.context?._value).toEqual({
      method: EnumSecurityStateType.Pgp,
      options: ['encryption'],
    })
  })

  it("resets value if it's disabled in another type", async () => {
    const view = renderSecurityField({
      securityAllowed: {
        [EnumSecurityStateType.Smime]: ['encryption', 'sign'],
        [EnumSecurityStateType.Pgp]: ['sign'],
      },
      securityDefaultOptions: {
        [EnumSecurityStateType.Smime]: ['sign'],
        [EnumSecurityStateType.Pgp]: ['sign'],
      },
    })

    const node = getNode('security')!

    const smime = view.getByRole('option', { name: 'S/MIME' })
    const pgp = view.getByRole('option', { name: 'PGP' })

    const encrypt = view.getByRole('option', { name: 'Encrypt' })
    const sign = view.getByRole('option', { name: 'Sign' })
    await view.events.click(encrypt)
    await view.events.click(sign)

    expect(node.context?._value).toEqual({
      method: EnumSecurityStateType.Smime,
      options: ['encryption', 'sign'],
    })

    await view.events.click(pgp)

    expect(node.context?._value).toEqual({
      method: EnumSecurityStateType.Pgp,
      options: ['sign'],
    })

    await view.events.click(smime)

    expect(node.context?._value).toEqual({
      method: EnumSecurityStateType.Smime,
      options: ['sign'],
    })
  })

  it('renders security options', async () => {
    const view = renderSecurityField({
      securityAllowed: {
        [EnumSecurityStateType.Smime]: ['encryption', 'sign'],
      },
    })

    const encrypt = view.getByRole('option', { name: 'Encrypt' })
    const sign = view.getByRole('option', { name: 'Sign' })

    expect(encrypt).toBeInTheDocument()
    expect(sign).toBeInTheDocument()

    expect(encrypt).toBeEnabled()
    expect(sign).toBeEnabled()
  })

  it('can check and uncheck options', async () => {
    const view = renderSecurityField({
      securityAllowed: {
        [EnumSecurityStateType.Smime]: ['encryption', 'sign'],
      },
    })

    const encrypt = view.getByRole('option', { name: 'Encrypt' })
    const sign = view.getByRole('option', { name: 'Sign' })

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'false')

    await view.events.click(encrypt)

    expect(encrypt).toHaveAttribute('aria-selected', 'true')
    expect(sign).toHaveAttribute('aria-selected', 'false')

    await view.events.click(encrypt)

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'false')

    await view.events.click(sign)

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'true')

    await view.events.click(sign)

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'false')
  })

  it("doesn't check disabled options", async () => {
    const view = renderSecurityField({
      securityAllowed: {
        [EnumSecurityStateType.Smime]: [],
      },
    })

    const encrypt = view.getByRole('option', { name: 'Encrypt' })
    const sign = view.getByRole('option', { name: 'Sign' })

    expect(encrypt).toBeDisabled()
    expect(sign).toBeDisabled()

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'false')

    await view.events.click(encrypt)

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'false')

    await view.events.click(encrypt)

    expect(encrypt).toHaveAttribute('aria-selected', 'false')
    expect(sign).toHaveAttribute('aria-selected', 'false')
  })

  it("doesn't submit form on click", async () => {
    const onSubmit = vi.fn()
    const view = renderComponent(Form, {
      form: true,
      formField: true,
      props: {
        onSubmit,
        schema: [
          {
            type: 'security',
            name: 'security',
            label: 'Security',
            props: {
              securityAllowed: {
                [EnumSecurityStateType.Smime]: ['encryption', 'sign'],
              },
            },
          },
        ],
      },
    })

    await view.events.click(
      await view.findByRole('option', { name: 'Encrypt' }),
    )

    expect(onSubmit).not.toHaveBeenCalled()

    await view.events.click(await view.findByRole('option', { name: 'Sign' }))

    expect(onSubmit).not.toHaveBeenCalled()
  })
})

describe('rendering security messages', () => {
  it("doesn't render if there are no messages", () => {
    const view = renderSecurityField({
      securityAllowed: {
        [EnumSecurityStateType.Smime]: ['encryption', 'sign'],
      },
      securityMessages: {},
    })

    expect(view.queryByTestId('tooltipTrigger')).not.toBeInTheDocument()
  })

  it('renders both messages correctly', async () => {
    const view = renderSecurityField({
      securityAllowed: {
        [EnumSecurityStateType.Smime]: ['encryption', 'sign'],
      },
      securityMessages: {
        [EnumSecurityStateType.Smime]: {
          encryption: { message: 'Custom encryption message' },
          sign: { message: 'Custom sign message' },
        },
      },
    })

    await view.events.click(view.getByTestId('tooltipTrigger'))

    expect(view.baseElement).toHaveTextContent(
      'Encryption: Custom encryption message',
    )
    expect(view.baseElement).toHaveTextContent('Sign: Custom sign message')
    expect(view.baseElement).toHaveTextContent('Security Information')
  })

  it("doesn't renders message if there is no messages in a different type", async () => {
    const view = renderSecurityField({
      securityAllowed: {
        [EnumSecurityStateType.Pgp]: ['encryption', 'sign'],
        [EnumSecurityStateType.Smime]: ['encryption', 'sign'],
      },
      securityMessages: {
        [EnumSecurityStateType.Smime]: {
          encryption: { message: 'Custom encryption message' },
          sign: { message: 'Custom sign message' },
        },
      },
    })

    await view.events.click(view.getByTestId('tooltipTrigger'))

    expect(view.baseElement).toHaveTextContent(
      'Encryption: Custom encryption message',
    )
    expect(view.baseElement).toHaveTextContent('Sign: Custom sign message')
    expect(view.baseElement).toHaveTextContent('Security Information')

    await view.events.click(view.getByRole('option', { name: 'PGP' }))

    expect(view.queryByTestId('tooltipTrigger')).not.toBeInTheDocument()
  })

  it('correctly renders messages for different types', async () => {
    const view = renderSecurityField({
      securityAllowed: {
        [EnumSecurityStateType.Pgp]: ['encryption', 'sign'],
        [EnumSecurityStateType.Smime]: ['encryption', 'sign'],
      },
      securityMessages: {
        [EnumSecurityStateType.Smime]: {
          encryption: { message: 'Custom S/MIME encryption message' },
          sign: { message: 'Custom S/MIME sign message' },
        },
        [EnumSecurityStateType.Pgp]: {
          encryption: { message: 'Custom PGP encryption message' },
          sign: { message: 'Custom PGP sign message' },
        },
      },
    })

    await view.events.click(view.getByTestId('tooltipTrigger'))

    expect(view.baseElement).toHaveTextContent(
      'Encryption: Custom S/MIME encryption message',
    )
    expect(view.baseElement).toHaveTextContent(
      'Sign: Custom S/MIME sign message',
    )
    expect(view.baseElement).toHaveTextContent('Security Information')

    await view.events.click(view.getByRole('option', { name: 'PGP' }))
    await view.events.click(view.getByTestId('tooltipTrigger'))

    expect(view.baseElement).toHaveTextContent(
      'Encryption: Custom PGP encryption message',
    )
    expect(view.baseElement).toHaveTextContent('Sign: Custom PGP sign message')
  })
})
