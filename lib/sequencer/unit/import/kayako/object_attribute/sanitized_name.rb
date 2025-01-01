# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::ObjectAttribute::SanitizedName < Sequencer::Unit::Import::Common::ObjectAttribute::SanitizedName
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_any_action

  uses :resource

  private

  def unsanitized_name
    resource['key']
  end
end
