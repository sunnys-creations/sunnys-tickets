# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Issue3550SetPretty < ActiveRecord::Migration[5.2]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    Cti::Log.reorder(created_at: :desc).limit(300).find_each do |log|
      log.set_pretty
      log.save!
    rescue
      Rails.logger.error "Issue3550SetPretty: Failed to migrate id #{log.id} with from '#{log.from}' and to '#{log.to}'"
    end
  end
end
