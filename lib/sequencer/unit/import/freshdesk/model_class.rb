# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::ModelClass < Sequencer::Unit::Common::Provider::Named
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_action :skipped, :failed

  uses :object

  MAP = {
    'Company'      => ::Organization,
    'Agent'        => ::User,
    'Contact'      => ::User,
    'Group'        => ::Group,
    'Ticket'       => ::Ticket,
    'Conversation' => ::Ticket::Article,
  }.freeze

  private

  def model_class
    MAP[object]
  end
end
