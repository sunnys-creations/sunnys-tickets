# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :data_privacy_task do
    created_by_id { 1 }
    updated_by_id { 1 }
    deletable     factory: :user
  end
end
