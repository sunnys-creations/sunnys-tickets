# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Caller log', authenticated_as: :authenticate, type: :system do
  let(:agent_phone)    { '0190111' }
  let(:customer_phone) { '0190333' }
  let(:cti_token)      { 'token1234' }
  let(:agent)          { create(:agent, phone: agent_phone) }
  let(:customer)       { create(:customer, phone: customer_phone) }
  let(:cti_on)         { true }

  let(:params) do
    {
      direction: 'in',
      from:      customer.phone,
      to:        agent_phone,
      callId:    '111',
      cause:     'busy',
    }
  end

  let(:first_params) { params.merge(event: 'newCall')  }
  let(:second_params) { params.merge(event: 'hangup')  }

  let(:visit_cti) do
    visit 'cti'
    ensure_websocket
  end

  let(:place_call) do
    post "#{Capybara.app_host}/api/v1/cti/#{cti_token}", params: first_params
    post "#{Capybara.app_host}/api/v1/cti/#{cti_token}", params: second_params
  end

  # Do the preperation before the authentication.
  def authenticate
    Setting.set('cti_integration', cti_on)
    Setting.set('cti_token', cti_token)

    agent
  end

  context 'when cti integration is on' do
    it 'shows the phone menu in nav bar' do
      visit '/'
      ensure_websocket

      within '#navigation .menu' do
        place_call
        expect(page).to have_link('Phone', href: '#cti')
      end
    end

    context 'when agent is on the phone' do
      let(:agent) do
        create(:agent, phone: agent_phone).tap do |user|
          user.preferences[:cti] = true
          user.save!
        end
      end

      let(:cti_log) do
        create(:cti_log,
               direction:   'in',
               from:        customer.phone,
               preferences: { from: [{ user_id: customer.id }] })
      end

      before { cti_log }

      it 'shows call and opens user profile on click' do
        visit '/'

        within '.call-widgets .user-card' do
          click_on customer.fullname
        end

        expect(current_url).to end_with("user/profile/#{customer.id}")
      end
    end
  end

  context 'when cti integration is not on' do
    let(:cti_on) { false }

    it 'does not show the phone menu in nav bar' do
      visit '/'

      within '#navigation .menu' do
        expect(page).to have_no_link('Phone', href: '#cti')
      end
    end
  end

  context 'when a customer call is answered' do
    let(:second_params) { params.merge(event: 'answer', answeringNumber: agent_phone) }

    context 'with known customer and without active tickets' do
      before do
        travel(-2.months)
        create(:ticket, customer: customer)
        travel_back

        visit_cti
        place_call
      end

      it 'opens a new ticket after phone call inbound' do
        within(:active_content) do
          expect(page).to have_text('New Ticket')
          expect(page).to have_css('input[name="title"][value="Call from 0190333"]', visible: :all)
          expect(page).to have_css('.tabsSidebar-tab[data-tab="customer"]', visible: :all)
          expect(page).to have_css("input[name=customer_id][value='#{customer.id}']", visible: :hide)
          expect(find('[name=customer_id_completion]').value).to eq "#{customer.fullname} <#{customer.email}>"
        end
      end
    end

    context 'without known customer and without active tickets' do
      let(:first_params) { params.merge(event: 'newCall', direction: 'out', from: '001', to: '002') }
      let(:second_params) { params.merge(event: 'answer', answeringNumber: agent_phone) }

      before do
        visit_cti
        place_call
      end

      it 'opens a new ticket after phone call inbound' do
        within(:active_content) do
          expect(page).to have_text('New Ticket')
          expect(page).to have_css("input[name='title'][value='Call from 0190333']", visible: :all)
          expect(page).to have_no_css('.tabsSidebar-tab[data-tab="customer"]')
          expect(find('[name=customer_id_completion]').value).to eq ''
        end
      end
    end

    context 'with known customer and with active tickets' do
      before do
        create(:ticket, customer: customer)
        visit_cti
        place_call
      end

      it 'opens the customer profile screen after phone call inbound with tickets in the last month' do
        within(:active_content) do
          expect(page).to have_text(customer.fullname)
        end
      end
    end

    context 'with phone number only known customer and without active tickets' do
      let(:customer_phone) { '0190444' }
      let(:customer)       { create(:customer, phone: customer_phone, email: nil, firstname: nil, lastname: nil) }

      before do
        travel(-2.months)
        create(:ticket, customer: customer)
        travel_back

        visit_cti
        place_call
      end

      it 'opens a new ticket after phone call inbound' do
        within(:active_content) do
          expect(page).to have_text('New Ticket')
          expect(page).to have_css('input[name="title"][value="Call from 0190444"]', visible: :all)
          expect(page).to have_css('.tabsSidebar-tab[data-tab="customer"]', visible: :all)
          expect(page).to have_css("input[name=customer_id][value='#{customer.id}']", visible: :hide)
          expect(find('[name=customer_id_completion]').value).to eq '0190444'
        end
      end
    end

  end

  context 'with incoming call' do
    before do
      visit_cti
      place_call
    end

    it 'increments the call counter notification badge' do
      within '[href="#cti"].js-phoneMenuItem' do
        counter = find('.counter')
        expect(counter).to have_content 1
      end
    end
  end

  context 'when incoming call is checked' do
    before do
      visit_cti
      place_call
    end

    it 'clears the call counter notification badge' do
      within :active_content do
        find('.table-checkbox input.js-check', visible: :all).check allow_label_click: true
      end

      within '[href="#cti"].js-phoneMenuItem' do
        expect(page).to have_no_selector('.counter')
      end
    end
  end

  # Regression test for #2018
  context 'phone numbers format' do
    before do
      visit_cti
      place_call
    end

    context 'with private number' do
      let(:customer_phone) { '007' }
      let(:agent_phone)    { '008' }

      it 'appears verbatim' do

        within :active_content do
          expect(page).to have_css('.js-callerLog', text: customer_phone)
            .and have_css('.js-callerLog', text: agent_phone)
        end
      end
    end

    context 'with e164 number' do
      let(:customer_phone) { '4930609854180' }
      let(:agent_phone)                   { '4930609811111' }
      let(:prettified_customer_phone)     { '+49 30 609854180' }
      let(:prettified_current_user_phone) { '+49 30 609811111' }

      it 'appears prettified' do
        within :active_content do
          expect(page).to have_css('.js-callerLog', text: prettified_customer_phone)
            .and have_css('.js-callerLog', text: prettified_current_user_phone)
        end
      end

      it 'done not appear verbatim' do
        within :active_content do
          expect(page).to have_no_selector('.js-callerLog', text: customer_phone)
        end
      end
    end
  end

  # Regression test for #2096
  context 'with inactive user' do
    before do
      visit_cti
      place_call
    end

    let(:customer) do
      create(:customer,
             phone:     customer_phone,
             active:    false,
             firstname: 'John',
             lastname:  'Doe')
    end

    it 'appears inactive' do
      within :active_content do
        expect(page).to have_css('span.avatar--inactive', text: 'JD')
      end
    end
  end

  # Regression test for #2075
  context 'when user is with organization name' do
    before do
      visit_cti
      place_call
    end

    let(:firstname) { 'John' }
    let(:lastname)          { 'Doe' }
    let(:organization_name) { 'Test Organization' }
    let(:organization)      { create(:organization, name: organization_name) }
    let(:full_name)         { "#{firstname} #{lastname}" }
    let(:customer) do
      create(:customer,
             phone:        customer_phone,
             firstname:    firstname,
             lastname:     lastname,
             organization: organization)
    end

    shared_examples 'showing user with thier organization name' do
      it 'shows user with thier organization name' do
        within :active_content do
          expect(page).to have_css(
            '.js-callerLog tr div.user-popover',
            text: "#{full_name} (#{organization_name})"
          )
        end
      end
    end

    context 'with call direction out' do
      let(:first_params) { params.merge(event: 'newCall', direction: 'out', from: agent_phone, to: customer.phone) }
      let(:second_params) { params.merge(event: 'hangup', direction: 'out', from: agent_phone, to: customer.phone) }

      it_behaves_like 'showing user with thier organization name'
    end

    context 'with call direction in' do
      let(:first_params) { params.merge(event: 'newCall', direction: 'in') }
      let(:second_params) { params.merge(event: 'hangup', direction: 'in') }

      it_behaves_like 'showing user with thier organization name'
    end
  end
end
