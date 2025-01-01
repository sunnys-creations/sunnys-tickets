# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class UpdateFormatSettings < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.find_by(name: 'ticket_define_email_from').update!(frontend: true)
    Setting.find_by(name: 'ticket_define_email_from_separator').update!(frontend: true)
  end
end
