# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :'active_record/session_store/session', aliases: %i[active_session] do
    transient do
      user { association :user }
    end

    session_id { SecureRandom.hex(16) }
    data do
      {
        'user_id'     => user&.id,
        'ping'        => Time.zone.now,
        'user_agent'  => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.128 Safari/537.36',
        '_csrf_token' => 'Yq3XiEgXxWPCURa/FvpXmptZCjgWhyPpGGIvZj9Eea0='
      }
    end
    created_at       { Time.zone.now }
    updated_at       { Time.zone.now }
  end
end
