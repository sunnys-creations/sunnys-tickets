# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# TODO: Check why editing customer's secondary organizations is not working.

RSpec.describe 'Mobile > Ticket > Information > Customer Edit', app: :mobile, authenticated_as: :authenticate, db_strategy: :reset, type: :system do
  let(:primary_organization)    { create(:organization) }
  let(:secondary_organizations) { create_list(:organization, 4) }
  let(:customer)                { create(:customer, organization: primary_organization, organizations: secondary_organizations, address: 'Berlin') }
  let(:group)                   { create(:group) }
  let(:ticket)                  { create(:ticket, customer: customer, group: group) }
  let(:agent)                   { create(:agent, groups: [group]) }
  let(:closed_tickets)          { create_list(:ticket, 2, customer: customer, group: group, state: Ticket::State.find_by(name: 'closed')) }

  def authenticate
    closed_tickets
    create(:object_manager_attribute_text, object_name: 'User', name: 'text_attribute', display: 'Text Attribute', screens: { edit: { '-all-' => { shown: true, required: false } }, view: { '-all-' => { shown: true, required: false } } })
    ObjectManager::Attribute.migration_execute
    agent
  end

  before do
    visit "/tickets/#{ticket.id}"

    wait_for_gql('apps/mobile/entities/ticket/graphql/queries/ticketWithMentionLimit.graphql')
    wait_for_gql('shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.graphql')

    # Switch to ticket information screen.
    click '[data-test-id="title-content"]'

    click_on('Customer')

    wait_for_gql('shared/entities/user/graphql/queries/user.graphql')
    wait_for_gql('shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.graphql', number: 2)
  end

  it 'shows customer data' do
    expect(find("[role=\"img\"][aria-label=\"Avatar (#{customer.fullname})\"]")).to have_text(customer.firstname[0].upcase + customer.lastname[0].upcase)
    expect(find('h2')).to have_text(customer.fullname)
    expect(find('h3')).to have_text(primary_organization.name)
    expect(find('section', text: 'Email')).to have_text(customer.email)
    expect(find('section', text: 'Address')).to have_text(customer.address)
    expect(page).to have_no_css('section', text: 'Text Attribute')

    click_on('Show 1 more')

    wait_for_gql('shared/entities/user/graphql/queries/user.graphql', number: 2)

    secondary_organizations.each do |organization|
      expect(page).to have_text(organization.name)
    end

    expect(find_all('[data-test-id="section-menu-item"]')[0]).to have_text("open\n1")
    expect(find_all('[data-test-id="section-menu-item"]')[1]).to have_text("closed\n2")
  end

  it 'supports editing customer data' do
    click_on('Edit Customer')

    wait_for_form_to_settle('user-edit')

    within_form(form_updater_gql_number: 2) do
      find_input('Text Attribute').type('foobar')
      find_input('First name').type('Foo')
      find_input('Last name').type('Bar')
      find_input('Address').type('München')
      find_autocomplete('Organization').search_for_option(secondary_organizations.first.name)

      # # Despite the name of the action, the following DESELECTS all secondary organizations for the customer.
      # #   This works because all these values are already selected in the field.
      # find_autocomplete('Secondary organizations').select_options(secondary_organizations.map { |organization| organization.name })
    end

    click_on('Save')

    wait_for_gql('shared/graphql/subscriptions/userUpdates.graphql')

    expect(find('[role="img"][aria-label="Avatar (Foo Bar)"]')).to have_text('FB')
    expect(find('h2')).to have_text('Foo Bar')
    expect(find('h3')).to have_text(secondary_organizations.first.name)
    expect(find('section', text: 'Address')).to have_text('München')
    expect(find('section', text: 'Text Attribute')).to have_text('foobar')

    # expect(page).to have_no_text('Secondary organizations')

    # secondary_organizations.each do |organization|
    #   expect(page).to have_no_text(organization.name)
    # end

    expect(customer.reload).to have_attributes(firstname: 'Foo', lastname: 'Bar', text_attribute: 'foobar', address: 'München')
  end

  it 'has an always enabled cancel button' do
    click_on('Edit Customer')

    wait_for_form_to_settle('user-edit')

    find_button('Cancel').click

    expect(page).to have_no_css('[role=dialog]')
  end

  it 'shows a confirmation dialog when leaving the screen' do
    click_on('Edit Customer')

    wait_for_form_to_settle('user-edit')

    within_form(form_updater_gql_number: 2) do
      find_input('Text Attribute').type('foobar')
    end

    find_button('Cancel').click

    within '[role=alert]' do
      expect(page).to have_text('Are you sure? You have unsaved changes that will get lost.')
    end
  end
end
