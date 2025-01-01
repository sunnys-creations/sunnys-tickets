# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/sequencer/unit/import/zendesk/object_attribute/attribute_type/base_examples'

RSpec.describe Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Date do
  it_behaves_like Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Base do
    let(:object_attribute_type) { 'data' }
    let(:object_attribute_data_option) do
      {
        null:   false,
        note:   'Example attribute description',
        future: true,
        past:   true,
        diff:   0,
      }
    end
  end
end
