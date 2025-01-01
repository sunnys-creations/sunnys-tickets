# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::SMIME < SecureMailing::Backend

  def self.active?
    Setting.get('smime_integration')
  end
end
