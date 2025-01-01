# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Ldap::ExternalSyncSource < Sequencer::Unit::Common::Provider::Named

  def external_sync_source
    'Ldap::User'
  end
end
