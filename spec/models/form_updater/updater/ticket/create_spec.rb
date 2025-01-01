# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'models/form_updater/concerns/checks_core_workflow_examples'
require 'models/form_updater/concerns/has_security_options_examples'
require 'models/form_updater/concerns/applies_ticket_template_examples'
require 'models/form_updater/concerns/applies_ticket_shared_draft_examples'
require 'models/form_updater/concerns/applies_split_ticket_article_examples'
require 'models/form_updater/concerns/stores_taskbar_state_examples'
require 'models/form_updater/concerns/applies_taskbar_state_examples'

RSpec.describe(FormUpdater::Updater::Ticket::Create) do
  subject(:resolved_result) do
    described_class.new(
      context:         context,
      relation_fields: relation_fields,
      meta:            meta,
      data:            data,
      id:              nil
    )
  end

  let(:group)         { create(:group, name: 'Example 1') }
  let(:group2)        { create(:group, name: 'Example 2') }
  let(:level1_group)  { create(:group, name: 'Depth 1-G1', parent: group) }
  let(:level1_group2) { create(:group, name: 'Depth 1-G2', parent: group) }
  let(:level2_group)  { create(:group, name: 'Depth 2-G1', parent: level1_group) }
  let(:user)          { create(:agent, groups: [group, group2, level1_group2, level2_group]) }
  let(:context)       { { current_user: user } }
  let(:meta)          { { initial: true, form_id: SecureRandom.uuid } }
  let(:data)          { {} }

  let(:relation_fields) do
    [
      {
        name:     'group_id',
        relation: 'group',
      },
      {
        name:     'state_id',
        relation: 'TicketState',
      },
      {
        name:     'priority_id',
        relation: 'TicketPriority',
      },
    ]
  end

  let(:expected_group_options) do
    [
      {
        value:    group.id,
        label:    group.name_last,
        disabled: false,
        children: [
          {
            value:    level1_group.id,
            label:    level1_group.name_last,
            disabled: true,
            children: [
              {
                value:    level2_group.id,
                label:    level2_group.name_last,
                disabled: false
              }
            ]
          },
          {
            value:    level1_group2.id,
            label:    level1_group2.name_last,
            disabled: false,
          },
        ]
      },
      {
        value:    group2.id,
        label:    group2.name_last,
        disabled: false
      }
    ]
  end

  let(:expected_result) do
    {
      'group_id'    => {
        options: expected_group_options
      },
      'state_id'    => {
        options: Ticket::State.by_category(:viewable_agent_new).reorder(name: :asc).map { |state| { value: state.id, label: state.name } },
      },
      'priority_id' => {
        options: Ticket::Priority.where(active: true).reorder(id: :asc).map { |priority| { value: priority.id, label: priority.name } },
      },
    }
  end

  context 'when resolving' do
    it 'returns all resolved relation fields with correct value + label' do
      expect(resolved_result.resolve[:fields]).to include(
        'group_id'    => include(expected_result['group_id']),
        'state_id'    => include(expected_result['state_id']),
        'priority_id' => include(expected_result['priority_id']),
      )
    end

    context 'with only one group for user' do
      let(:user) { create(:agent, groups: [level2_group]) }

      it 'returns group_id as integer' do
        expect(resolved_result.resolve[:fields]).to include(
          'group_id' => include(value: level2_group.id)
        )
      end
    end

    context 'when no permission on all parent groups' do
      let(:user) { create(:agent, groups: [group2, level2_group]) }
      let(:expected_group_options) do
        [
          {
            value:    group.id,
            label:    group.name_last,
            disabled: true,
            children: [
              {
                value:    level1_group.id,
                label:    level1_group.name_last,
                disabled: true,
                children: [
                  {
                    value:    level2_group.id,
                    label:    level2_group.name_last,
                    disabled: false
                  }
                ]
              },
            ]
          },
          {
            value:    group2.id,
            label:    group2.name_last,
            disabled: false
          }
        ]
      end

      it 'returns current group options' do
        expect(resolved_result.resolve[:fields]).to include(
          'group_id'    => include(expected_result['group_id']),
        )
      end
    end

    context 'when group_id is given in data' do
      let(:data) { { 'group_id' => group.id } }

      it 'returns no new value for group' do
        expect(resolved_result.resolve[:fields]).to not_include(
          'group_id' => include(value: group.id)
        )
      end
    end

    context 'with different default priority' do
      before do
        Ticket::Priority.find(1).update!(default_create: true)
      end

      it 'returns initial value for priority_id' do
        expect(resolved_result.resolve[:fields]).to include(
          'priority_id' => include(initialValue: 1)
        )
      end
    end

    context 'when customer_id should be prefilled' do
      let(:meta)     { { initial: true, form_id: SecureRandom.uuid, additional_data: { 'customer_id' => customer.id } } }
      let(:customer) { create(:customer, organization: create(:organization)) }

      it 'returns initial value for customer_id' do
        expect(resolved_result.resolve[:fields]).to include(
          'customer_id' => include(
            initialValue: customer.id,
            options:      [{
              value:   customer.id,
              label:   customer.fullname,
              heading: customer.organization.name,
              object:  customer.attributes
                        .slice('active', 'email', 'firstname', 'fullname', 'image', 'lastname', 'mobile', 'out_of_office', 'out_of_office_end_at', 'out_of_office_start_at', 'phone', 'source', 'vip')
                        .merge({
                                 '__typename' => 'User',
                                 'id'         => Gql::ZammadSchema.id_from_internal_id('User', customer.id),
                               })

            }]
          )
        )
      end
    end
  end

  include_examples 'FormUpdater::ChecksCoreWorkflow', object_name: 'Ticket'
  include_examples 'FormUpdater::HasSecurityOptions', type: 'create'
  include_examples 'FormUpdater::AppliesTicketTemplate'
  include_examples 'FormUpdater::AppliesTicketSharedDraft', draft_type: 'start'
  include_examples 'FormUpdater::AppliesSplitTicketArticle'
  include_examples 'FormUpdater::StoresTaskbarState', taskbar_key: 'TicketCreateScreen-1234', taskbar_callback: 'TicketCreate', store_state_collect_group_key: nil, store_state_group_keys: nil
  include_examples 'FormUpdater::AppliesTaskbarState', taskbar_key: 'TicketCreateScreen-1234', taskbar_callback: 'TicketCreate', apply_state_group_keys: nil
end
