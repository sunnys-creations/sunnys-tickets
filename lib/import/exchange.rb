# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Import
  class Exchange < Import::IntegrationBase
    include Import::Mixin::Sequence

    private

    def sequence_name
      'Import::Exchange::FolderContacts'
    end
  end
end
