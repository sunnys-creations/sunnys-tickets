# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::Request < Sequencer::Unit::Common::Provider::Attribute
  class TimeEntry < Sequencer::Unit::Import::Freshdesk::Request::Generic
    attr_reader :ticket

    def initialize(...)
      super
      @ticket = request_params.delete(:ticket)
    end

    def api_path
      "tickets/#{ticket['id']}/time_entries"
    end
  end
end
