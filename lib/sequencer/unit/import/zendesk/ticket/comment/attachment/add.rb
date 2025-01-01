# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Ticket::Comment::Attachment::Add < Sequencer::Unit::Base
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action
  include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure

  skip_action :skipped

  uses :instance, :resource, :response, :model_class

  def process
    ::Store.create!(
      object:        model_class.name,
      o_id:          instance.id,
      data:          response.body,
      filename:      resource.file_name,
      preferences:   store_preferences,
      created_by_id: 1
    )
  rescue => e
    handle_failure(e)
  end

  private

  def store_preferences
    output = { 'Content-Type' => resource.content_type }

    if Store.resizable_mime? resource.content_type
      output[:resizable]       = true
      output[:content_preview] = true
    end

    output
  end
end
