# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'text modules' do |path:, ticket: nil|
  let!(:agent_fixed_name)           { create(:agent, firstname: 'FFFF1', lastname: 'GGGG1', groups: [Group.find_by(name: 'Users')]) }
  let!(:group1)                     { create(:group) }
  let!(:group2)                     { create(:group) }
  let!(:text_module_without_group1) { create(:text_module, name: 'aaa', keywords: "test dummy #{Faker::Superhero.prefix}") }
  let!(:text_module_without_group2) { create(:text_module, name: 'bbb', keywords: "test dummy #{Faker::Superhero.prefix}") }
  let!(:text_module_group1)         { create(:text_module, name: 'ccc', keywords: "test dummy #{Faker::Superhero.prefix}", groups: [group1]) }
  let!(:text_module_group2)         { create(:text_module, name: 'ddd', keywords: "test dummy #{Faker::Superhero.prefix}", groups: [group2]) }

  it 'shows when send ::' do
    refresh # workaround to get new created objects from db
    visit path
    within(:active_content) do
      set_tree_select_value('group_id', Group.first.name)
      find(:richtext).send_keys(':')
      find(:richtext).send_keys(':')
      expect(page).to have_selector(:text_module, text_module_without_group1.id)
    end
  end

  it 'does not break after usage of Ctrl/Command+Backspace' do
    visit path
    within(:active_content) do
      find(:richtext).send_keys(':')
      find(:richtext).send_keys(':')
      find(:richtext).send_keys('bur')

      # The click is needed to get the focus back to the field for chrome.
      find(:richtext).click
      find(:richtext).send_keys([magic_key, :backspace])

      find(:richtext).send_keys('Some other text')
      find(:richtext).send_keys(:enter)
      expect(find(:richtext)).to have_text 'Some other text'
    end
  end

  it 'does not show when send :enter:' do
    visit path
    within(:active_content) do
      set_tree_select_value('group_id', Group.first.name)
      find(:richtext).send_keys(':')
      find(:richtext).send_keys(:enter)
      find(:richtext).send_keys(':')
      expect(page).to have_no_selector(:text_module, text_module_without_group1.id)
      expect(page).to have_no_selector(:text_module, text_module_without_group2.id)
    end
  end

  it 'does not break search on backspace' do
    visit path
    within(:active_content) do
      set_tree_select_value('group_id', Group.first.name)
      find(:richtext).send_keys('@@agen')
      find(:richtext).send_keys(:backspace)
      expect(page).to have_no_text('No results found')
    end
  end

  it 'does delete empty mentions (issue #3636 / FF only)' do
    visit path
    within(:active_content) do
      set_tree_select_value('group_id', Group.first.name)
      find(:richtext).send_keys('@@FFFF1')
      await_empty_ajax_queue
      find(:richtext).send_keys(:enter)
      find(:richtext).send_keys(:enter)
      (agent_fixed_name.firstname.length + agent_fixed_name.lastname.length + 2).times do
        find(:richtext).send_keys(:backspace)
      end
      expect(find(:richtext)).to have_no_css('a[data-mention-user-id]', visible: :all)
    end
  end

  it 'does delete empty mentions (issue #3636 / simulation)' do
    visit path
    within(:active_content) do
      set_tree_select_value('group_id', Group.first.name)
      find(:richtext).send_keys('@@FFFF1')
      await_empty_ajax_queue
      find(:richtext).send_keys(:enter)
      find(:richtext).send_keys(:enter)
      find(:richtext).send_keys('test')
      page.execute_script("$('a[data-mention-user-id]').first().html('<br>')")
      find(:richtext).send_keys(:backspace)
      expect(find(:richtext).all('a[data-mention-user-id]', visible: :all).count).to eq(0)
    end
  end

  it 'does not delete parts of the text on multiple mentions (issue #3717)' do
    visit path
    within(:active_content) do
      set_tree_select_value('group_id', Group.first.name)
      find(:richtext).send_keys('Testing Testy')
      find(:richtext).send_keys('@@FFFF1')
      await_empty_ajax_queue
      find(:richtext).send_keys(:enter)
      await_empty_ajax_queue
      find(:richtext).send_keys(:enter)
      find(:richtext).send_keys('Testing Testy ')
      find(:richtext).send_keys('@@FFFF1')
      await_empty_ajax_queue
      find(:richtext).send_keys(:enter)
      await_empty_ajax_queue

      expect(find(:richtext).text).to include('Testing TestyFFFF1 GGGG1')
      expect(find(:richtext).text).to include('Testing Testy FFFF1 GGGG1')
    end
  end

  it 'does not delete line breaks of text with mentions (issue #3717)' do
    visit path
    within(:active_content) do
      set_tree_select_value('group_id', Group.first.name)
      find(:richtext).send_keys('@@FFFF1')
      await_empty_ajax_queue
      find(:richtext).send_keys(:enter)
      find(:richtext).send_keys(' Testing Testy')
      find(:richtext).send_keys(:enter)
      find(:richtext).send_keys(:enter)
      find(:richtext).send_keys(:backspace)
      find(:richtext).send_keys('@@FFFF1')
      await_empty_ajax_queue
      find(:richtext).send_keys(:enter)
      expect(find(:richtext).text).to include("FFFF1 GGGG1 Testing Testy\nFFFF1 GGGG1")
    end
  end

  it 'supports group-dependent text modules' do
    visit '/'

    # give user access to all groups including those created
    # by using FactoryBot outside of the example
    group_names_access_map = Group.pluck(:name).index_with do |_group_name|
      'full'.freeze
    end

    current_user do |user|
      user.group_names_access_map = group_names_access_map
      user.save!
    end

    refresh # workaround to get changed settings from db
    visit path
    within(:active_content) do
      set_tree_select_value('group_id', group1.name)
      find(:richtext).send_keys('::')

      expect(page).to have_selector(:text_module, text_module_without_group1.id)
      expect(page).to have_selector(:text_module, text_module_without_group2.id)
      expect(page).to have_selector(:text_module, text_module_group1.id)
      expect(page).to have_no_selector(:text_module, text_module_group2.id)

      set_tree_select_value('group_id', group2.name)
      find(:richtext).send_keys('::')

      expect(page).to have_selector(:text_module, text_module_without_group1.id)
      expect(page).to have_selector(:text_module, text_module_without_group2.id)
      expect(page).to have_no_selector(:text_module, text_module_group1.id)
      expect(page).to have_selector(:text_module, text_module_group2.id)
    end
  end

  it 'orders text modules by alphabet' do
    refresh # workaround to get changed settings from db
    visit path

    within(:active_content) do
      find(:richtext).send_keys('::')
      find(:richtext).send_keys('dummy')

      find('.text-modules-box')

      expected_order = [
        "#{text_module_without_group2.name}\n#{text_module_without_group2.keywords}",
        "#{text_module_without_group1.name}\n#{text_module_without_group1.keywords}",
      ]
      if path == 'ticket/create'
        expected_order = [
          "#{text_module_group2.name}\n#{text_module_group2.keywords}",
          "#{text_module_group1.name}\n#{text_module_group1.keywords}",
          "#{text_module_without_group2.name}\n#{text_module_without_group2.keywords}",
          "#{text_module_without_group1.name}\n#{text_module_without_group1.keywords}",
        ]
      end

      shown_text_modules = find_all(:css, '.text-modules-box li')
      expect(shown_text_modules.length).to eq(expected_order.length)

      shown_text_modules_text = shown_text_modules.map(&:text)
      expect(shown_text_modules_text).to eq(expected_order)
    end
  end

  context 'when text module refers external data source', authenticated_as: :authenticate, db_strategy: :reset do
    let(:custom_attribute) { create(:object_manager_attribute_autocompletion_ajax_external_data_source) }
    let(:text_module_external) do
      create(:text_module,
             name:    'external data source',
             content: "external \#{ticket.#{custom_attribute.name}.value}")
    end

    def authenticate
      text_module_external
      custom_attribute
      ObjectManager::Attribute.migration_execute
      true
    end

    context 'when ticket external field value is not set' do
      it 'inserts text module with placeholder' do
        visit path
        within(:active_content) do
          find(:richtext).send_keys('::ext')
          page.send_keys(:enter)
          expect(find(:richtext)).to have_text 'external -'
        end
      end
    end

    if path.starts_with? '#ticket/zoom'
      context 'when ticket external field value is set' do
        before do
          ticket.reload[custom_attribute.name] = { value: 'aaa', label: 'AAA' }
          ticket.save!
        end

        it 'inserts text module with external value' do
          visit path
          within(:active_content) do
            find(:richtext).send_keys('::ext')
            page.send_keys(:enter)
            expect(find(:richtext)).to have_text 'external AAA'
          end
        end
      end
    end
  end

  context 'when Group restriction for text modules not working on ticket creation (specific scenario only) #4358', authenticated_as: :authenticate do
    let(:agent) { create(:agent, groups: [group1]) }

    def authenticate
      agent
    end

    it 'does show group related text modules when the group is hidden' do
      ticket&.update(group: group1)
      visit path
      within(:active_content) do
        expect(page).to have_css('[data-attribute-name=group_id].is-hidden', visible: :all)
        find(:richtext).send_keys(':')
        find(:richtext).send_keys(':')
        expect(page).to have_selector(:text_module, text_module_group1.id)
      end
    end
  end
end
