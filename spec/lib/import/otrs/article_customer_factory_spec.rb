# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/factory_examples'

RSpec.describe Import::OTRS::ArticleCustomerFactory do
  it_behaves_like 'Import::Factory'
end
