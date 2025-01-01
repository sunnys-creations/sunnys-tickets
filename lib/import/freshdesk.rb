# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Import
  class Freshdesk < Import::Base
    include Import::Mixin::Sequence

    def start
      process
    end

    def sequence_name
      'Import::Freshdesk::Full'
    end
  end
end
