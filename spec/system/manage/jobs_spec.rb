# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > Job', type: :system do
  context 'ajax pagination' do
    include_examples 'pagination', model: :job, klass: Job, path: 'manage/job'
  end
end
