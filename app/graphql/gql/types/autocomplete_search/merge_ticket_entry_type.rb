# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::AutocompleteSearch
  class MergeTicketEntryType < EntryType
    description 'Type that represents an autocomplete merge ticket entry.'

    field :ticket, Gql::Types::TicketType, null: false
  end
end
