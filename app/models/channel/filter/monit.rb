# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Channel::Filter::Monit < Channel::Filter::MonitoringBase
  def self.integration_name
    'monit'
  end
end
