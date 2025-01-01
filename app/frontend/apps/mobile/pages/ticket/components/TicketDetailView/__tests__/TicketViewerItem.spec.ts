// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { EnumTaskbarApp } from '#shared/graphql/types.ts'

import TicketViewerItem from '../TicketViewerItem.vue'

describe('displaying single ticket viewer items', () => {
  const user = {
    id: '1234',
    firstname: 'John',
    lastname: 'Doe',
    fullname: 'John Doe',
  }

  it('displays the avatar and user name with desktop icon', () => {
    const view = renderComponent(TicketViewerItem, {
      props: {
        user,
        app: EnumTaskbarApp.Desktop,
        editing: false,
      },
    })

    expect(view.getByText('JD')).toBeInTheDocument()
    expect(view.getByText('John Doe')).toBeInTheDocument()
    expect(view.getByIconName('desktop')).toBeInTheDocument()
  })

  it('with desktop editing icon', () => {
    const view = renderComponent(TicketViewerItem, {
      props: {
        user,
        app: EnumTaskbarApp.Desktop,
        editing: true,
      },
    })

    expect(view.getByText('JD')).toBeInTheDocument()
    expect(view.getByText('John Doe')).toBeInTheDocument()
    expect(view.getByIconName('desktop-edit')).toBeInTheDocument()
  })

  it('with only editing icon', () => {
    const view = renderComponent(TicketViewerItem, {
      props: {
        user,
        app: EnumTaskbarApp.Mobile,
        editing: true,
      },
    })

    expect(view.getByText('JD')).toBeInTheDocument()
    expect(view.getByText('John Doe')).toBeInTheDocument()
    expect(view.getByIconName('edit')).toBeInTheDocument()
  })

  it('without any icon and idle state', () => {
    const view = renderComponent(TicketViewerItem, {
      props: {
        user,
        app: EnumTaskbarApp.Mobile,
        editing: false,
      },
    })

    expect(view.getByText('JD')).toBeInTheDocument()
    expect(view.getByText('John Doe')).toBeInTheDocument()
    expect(view.queryByIconName('desktop-edit')).not.toBeInTheDocument()
    expect(view.queryByIconName('desktop')).not.toBeInTheDocument()
    expect(view.queryByIconName('edit')).not.toBeInTheDocument()

    const avatar = view.getByTestId('common-avatar')
    expect(avatar).not.toHaveClass('grayscale')
  })

  it('with idle state', () => {
    const view = renderComponent(TicketViewerItem, {
      props: {
        user,
        app: EnumTaskbarApp.Mobile,
        editing: false,
        idle: true,
      },
    })

    const avatar = view.getByTestId('common-avatar')
    expect(avatar).toHaveClass('grayscale')
  })
})
