# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Tag::Assignment::Base < BaseMutation # rubocop:disable GraphQL/ObjectDescription
    protected

    def fetch_object(object_id)
      Gql::ZammadSchema
        .authorized_object_from_id(
          object_id,
          user:  context.current_user,
          query: :agent_update_access?,
          type:  [::Ticket, ::KnowledgeBase::Answer]
        )
    end
  end
end
