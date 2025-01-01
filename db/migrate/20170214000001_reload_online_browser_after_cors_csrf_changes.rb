# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ReloadOnlineBrowserAfterCorsCsrfChanges < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    AppVersion.set(true, 'app_version')
  end
end
