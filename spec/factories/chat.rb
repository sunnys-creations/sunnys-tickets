# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :chat do
    sequence(:name) { |n| "Chat #{n}" }
    max_queue       { 5 }
    active          { true }
    created_by_id   { 1 }
    updated_by_id   { 1 }
  end
end
