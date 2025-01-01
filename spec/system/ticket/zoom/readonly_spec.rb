# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Access Zoom', authenticated_as: :user, type: :system do
  let(:group) { create(:group) }

  let!(:ticket) do
    create(:ticket, group: group).tap do |ticket|
      ticket.tag_add('Tag', 1)
      create(:link, from: create(:ticket, group: group), to: ticket)
      create(:ticket_article, ticket: ticket)
    end
  end

  let(:user) do
    create(:agent).tap do |agent|
      agent.user_groups.create! group: group, access: group_access
    end
  end

  let(:name)       { attribute.name }
  let(:data_type)  { attribute.data_type }
  let(:display)    { attribute.display }
  let(:value)      { data_option['options'].values.first }

  let(:data_option) do
    {
      'default'  => '',
      'options'  => { 'value_1' => 'value_1', 'value_2' => 'value_2', 'value_3' => 'value_3' },
      'relation' => '', 'nulloption' => true, 'multiple' => false,
      'null'     => true, 'translate' => true, 'maxlength' => 255
    }
  end

  let(:multi_data_option) do
    data_option.merge({ 'multiple' => true })
  end

  before do
    visit "ticket/zoom/#{ticket.id}"
  end

  shared_examples 'elements' do
    it 'verify all elements available' do
      %w[TAGS LINKS].each do |element|
        expect(page).to have_content(element)
      end
    end
  end

  context 'with full access' do
    let(:group_access) { :full }

    include_examples 'elements'

    it 'shows tag, and link modification buttons' do
      expect(page).to have_css('.tags .icon-diagonal-cross')
      expect(page).to have_content('+ Add Tag')
      expect(page).to have_css('.links .icon-diagonal-cross')
      expect(page).to have_content('+ Add Link')
    end

    context 'with select, treeselect, multiselect and multi-treeselect fields', authenticated_as: :authenticated, db_strategy: :reset do
      def authenticated
        attribute
        ObjectManager::Attribute.migration_execute
        user
      end

      shared_examples 'allow agents to select another value' do
        it 'allows agents to select another value' do
          within attribute_selector do
            expect(page).to have_content(%r{#{display}}i)
            find(".controls select[name=#{name}]", visible: :all).select value
            expect(page).to have_select(name, selected: value, visible: :all)
          end
        end
      end

      shared_examples 'allows agents to select a treeselect/multi-treeselect value' do
        it 'allows agents to select another value' do
          within attribute_selector { expect(page).to have_content(%r{#{display}}i) }

          dropdown_toggle
          within attribute_selector do
            find(".js-optionsList > .js-option[data-value=#{value}]", visible: :all).click
            expect(page).to have_element
          end
        end
      end

      context 'with a select field' do
        let(:attribute) { create(:object_manager_attribute_select, :required_screen, data_option: data_option) }

        include_examples 'allow agents to select another value'
      end

      context 'with a multiselect field' do
        let(:attribute) { create(:object_manager_attribute_multiselect, :required_screen, data_option: multi_data_option) }

        include_examples 'allow agents to select another value'
      end

      context 'with a tree select field' do
        let(:attribute)    { create(:object_manager_attribute_tree_select, :required_screen, data_option: data_option) }
        let(:have_element) { have_field(name, with: value, visible: :all) }

        include_examples 'allows agents to select a treeselect/multi-treeselect value'
      end

      context 'with a multi tree select field' do
        let(:attribute) { create(:object_manager_attribute_multi_tree_select, :required_screen, data_option: multi_data_option) }
        let(:have_element) { have_select(name, selected: value, visible: :all) }

        include_examples 'allows agents to select a treeselect/multi-treeselect value'
      end
    end
  end

  context 'with read access' do
    let(:group_access) { :read }

    include_examples 'elements'

    it 'shows no tag and link modification buttons' do
      expect(page).to have_no_selector('.tags .icon-diagonal-cross')
      expect(page).to have_no_content('+ Add Tag')
      expect(page).to have_no_selector('.links .icon-diagonal-cross')
      expect(page).to have_no_content('+ Add Link')
    end

    it 'shows no ticket actions' do
      expect(page).to have_no_selector('.js-submit')
      expect(page).to have_no_selector('.js-secondaryActionButtonLabel')
      expect(page).to have_no_selector('.js-ArticleAction[data-type=internal]')
      expect(page).to have_no_selector('.js-highlight')
    end

    it 'shows no ticket sidebar ticket actions' do
      click '.sidebar .js-headline'
      expect(page).to have_no_text('Change Customer')
      expect(page).to have_no_text('Merge')
    end

    it 'shows no ticket sidebar customer ticket actions' do
      click '.tabsSidebar-tab[data-tab=customer]'
      click '.sidebar .js-headline'
      expect(page).to have_no_text('Change Customer')
    end

    context 'with select, treeselect, multiselect and multi-treeselect fields', authenticated_as: :authenticated, db_strategy: :reset do
      def authenticated
        attribute
        ObjectManager::Attribute.migration_execute
        user
      end

      shared_examples 'does not allow agents to select another value' do
        it 'does not allow agents to select another value' do
          within attribute_selector do
            expect(page).to have_content(%r{#{display}}i)
            find(".controls select[name=#{name}]", visible: :all).select value, disabled: true
            expect(page).to have_no_select(name, selected: value, visible: :all, disabled: :all)
          end
        end
      end

      shared_examples 'does not allow agents to select another treeselect/multi-treeselect value' do
        it 'does not allow agents to select another value' do
          within attribute_selector do
            expect(page).to have_content(%r{#{display}}i)
            find('.controls .dropdown .dropdown-toggle').click
            expect(page).to have_no_css(".js-optionsList > .js-option[data-value=#{value}]", wait: 15)
          end
        end
      end

      context 'with a select field' do
        let(:attribute) { create(:object_manager_attribute_select, :required_screen, data_option: data_option) }

        include_examples 'does not allow agents to select another value'
      end

      context 'with a multiselect field' do
        let(:attribute) { create(:object_manager_attribute_multiselect, :required_screen, data_option: multi_data_option) }

        include_examples 'does not allow agents to select another value'
      end

      context 'with a tree select field' do
        let(:attribute) { create(:object_manager_attribute_tree_select, :required_screen, data_option: data_option) }

        include_examples 'does not allow agents to select another treeselect/multi-treeselect value'
      end

      context 'with a multi tree select field' do
        let(:attribute) { create(:object_manager_attribute_multi_tree_select, :required_screen, data_option: multi_data_option) }

        include_examples 'does not allow agents to select another treeselect/multi-treeselect value'
      end
    end
  end

  def dropdown_toggle
    loop do
      find('.controls .dropdown .dropdown-toggle').click

      break if find_all(".js-optionsList > .js-option[data-value=#{value}]", allow_reload: true, wait: 0).any?

      # If we could not find the dropdown options, we sleep and try again.
      sleep 0.1
    end
  end

  def attribute_selector
    ".sidebar-content .#{data_type}[data-attribute-name=#{name}]"
  end
end
