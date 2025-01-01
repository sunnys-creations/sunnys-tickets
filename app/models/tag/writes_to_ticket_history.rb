# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Records added/removed tags also in the ticket history.
module Tag::WritesToTicketHistory
  extend ActiveSupport::Concern

  included do
    after_create  :write_tag_added_to_ticket_history
    after_destroy :write_tag_removed_to_ticket_history

    # used to forward the sourceable to the tag model
    # to keep track of added and removed tags by
    # postmaster filters, triggers and schedulers
    attr_accessor :sourceable
  end

  private

  def write_tag_added_to_ticket_history

    return true if tag_object.name != 'Ticket'

    History.add(
      o_id:              o_id,
      history_type:      'added',
      history_object:    'Ticket',
      history_attribute: 'tag',
      value_to:          tag_item.name,
      created_by_id:     created_by_id,
      sourceable:        sourceable,
    )
  end

  def write_tag_removed_to_ticket_history

    return true if tag_object.name != 'Ticket'

    History.add(
      o_id:              o_id,
      history_type:      'removed',
      history_object:    'Ticket',
      history_attribute: 'tag',
      value_to:          tag_item.name,
      created_by_id:     created_by_id,
      sourceable:        sourceable,
    )
  end
end
