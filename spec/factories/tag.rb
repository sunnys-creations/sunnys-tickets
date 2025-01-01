# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :tag do
    transient do
      o   { Ticket.first }
      tag { 'blub' }
    end

    tag_item_id   { Tag::Item.lookup_by_name_and_create(tag).id }
    o_id          { o.id }
    created_by_id { 1 }

    tag_object_id do
      Tag::Object.lookup(name: o.class.name)&.id || create(:'tag/object', name: o.class.name).id
    end
  end
end
