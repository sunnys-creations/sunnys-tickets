# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SchedulerSessionTimeout < ActiveRecord::Migration[5.2]
  def change

    return if !Setting.exists?(name: 'system_init_done')

    Scheduler.find_by(name: 'Cleanup dead sessions.').update(period: 1.hour)
  end
end
