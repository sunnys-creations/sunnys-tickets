# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::ObjectAttribute::Add < Sequencer::Unit::Base
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_any_action

  uses :config

  def process
    ObjectManager::Attribute.add(config)
  end
end
