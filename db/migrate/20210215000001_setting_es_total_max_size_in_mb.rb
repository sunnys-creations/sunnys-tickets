# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SettingEsTotalMaxSizeInMb < ActiveRecord::Migration[5.2]
  def up
    Setting.create_if_not_exists(
      title:       'Elasticsearch Total Payload Size',
      name:        'es_total_max_size_in_mb',
      area:        'SearchIndex::Elasticsearch',
      description: 'Define max. payload size for Elasticsearch.',
      state:       300,
      preferences: { online_service_disable: true },
      frontend:    false
    )
  end
end
