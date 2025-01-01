# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TicketUserTicketCounterJob, type: :job do

  let!(:customer) { create(:user) }

  let!(:ticket_states) do
    {
      open:   Ticket::State.by_category(:open).first,
      closed: Ticket::State.by_category(:closed).first,
    }
  end

  let!(:tickets) do
    {
      open:   create_list(:ticket, 2, state_id: ticket_states[:open].id, customer_id: customer.id),
      closed: create_list(:ticket, 1, state_id: ticket_states[:closed].id, customer_id: customer.id),
    }
  end

  it 'checks if customer has no ticket count in preferences' do
    customer.reload
    expect(customer[:preferences][:tickets_open]).to be_falsey
    expect(customer[:preferences][:tickets_closed]).to be_falsey
  end

  it 'checks if customer ticket count has been updated in preferences' do
    described_class.perform_now(
      customer.id,
      customer.id,
    )
    customer.reload

    expect(customer[:preferences][:tickets_open]).to be tickets[:open].count
    expect(customer[:preferences][:tickets_closed]).to be tickets[:closed].count
  end
end
