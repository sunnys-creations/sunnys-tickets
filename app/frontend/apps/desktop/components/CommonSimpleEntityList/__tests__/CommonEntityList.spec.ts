// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { describe } from 'vitest'

import renderComponent from '#tests/support/components/renderComponent.ts'

import {
  organizationOption,
  userOption,
} from '#desktop/components/CommonSimpleEntityList/__tests__/support/entityOptions.ts'
import CommonSimpleEntityList from '#desktop/components/CommonSimpleEntityList/CommonSimpleEntityList.vue'
import { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'

describe('CommonSimpleEntityList', () => {
  describe('Entity Types', () => {
    it('renders a list of users', () => {
      const wrapper = renderComponent(CommonSimpleEntityList, {
        router: true,
        props: {
          id: 'test-id',
          type: EntityType.User,
          entity: {
            array: userOption,
            totalCount: userOption.length,
          },
        },
      })

      expect(wrapper.getByText('Nicole Braun')).toBeInTheDocument()
      expect(wrapper.getByText('Thomas Ernst')).toBeInTheDocument()
      expect(
        wrapper.getByLabelText('Avatar (Nicole Braun)'),
      ).toBeInTheDocument()
      expect(
        wrapper.getByLabelText('Avatar (Thomas Ernst)'),
      ).toBeInTheDocument()
      expect(wrapper.getAllByTestId('common-link')).toHaveLength(3)
      expect(wrapper.getAllByTestId('common-link').at(0)).toHaveAttribute(
        'href',
        '/user/profile/2',
      )
    })

    it('renders a list of organizations', () => {
      const wrapper = renderComponent(CommonSimpleEntityList, {
        router: true,
        props: {
          id: 'test-id',
          type: EntityType.Organization,
          entity: {
            array: organizationOption,
            totalCount: organizationOption.length,
          },
        },
      })

      expect(wrapper.getByText('Spar')).toBeInTheDocument()
      expect(wrapper.getByText('Mercadona')).toBeInTheDocument()
      expect(wrapper.getByLabelText('Avatar (Spar)')).toBeInTheDocument()
      expect(wrapper.getByLabelText('Avatar (Mercadona)')).toBeInTheDocument()
      expect(wrapper.getAllByTestId('common-link')).toHaveLength(3)
      expect(wrapper.getAllByTestId('common-link').at(0)).toHaveAttribute(
        'href',
        '/organizations/2',
      )
    })
  })

  it('supports entity label', () => {
    const wrapper = renderComponent(CommonSimpleEntityList, {
      router: true,
      props: {
        id: 'test-id',
        label: 'Foo Label',
        type: EntityType.User,
        entity: {
          array: userOption,
          totalCount: userOption.length,
        },
      },
    })

    expect(wrapper.getByText('Foo Label')).toBeInTheDocument()
  })

  it('hides load more button if less than three entities are available', () => {
    const wrapper = renderComponent(CommonSimpleEntityList, {
      router: true,
      props: {
        id: 'test-id',
        type: EntityType.User,
        entity: {
          array: userOption,
          totalCount: userOption.length,
        },
      },
    })

    expect(
      wrapper.queryByRole('button', {
        name: /show/i,
      }),
    ).not.toBeInTheDocument()
  })

  it('emits load-more event if more than three entities are available', async () => {
    const wrapper = renderComponent(CommonSimpleEntityList, {
      router: true,
      props: {
        id: 'test-id',
        type: EntityType.User,
        entity: {
          array: userOption,
          totalCount: userOption.length + 1,
        },
      },
    })

    await wrapper.events.click(
      wrapper.getByRole('button', {
        name: 'Show 1 more',
      }),
    )

    expect(wrapper.emitted()['load-more']).toHaveLength(1)
  })

  it('displays message if list is empty', async () => {
    const wrapper = renderComponent(CommonSimpleEntityList, {
      router: true,
      props: {
        id: 'test-id',
        type: EntityType.User,
        entity: {
          array: [],
          totalCount: 0,
        },
      },
    })

    expect(wrapper.getByText('No members found')).toBeInTheDocument()
  })
})
