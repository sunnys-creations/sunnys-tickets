# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require 'system/examples/core_workflow_examples'

RSpec.describe 'Organization Profile', type: :system do
  let(:organization) { create(:organization) }

  describe 'when calling without session' do
    describe 'redirect to' do
      it 'login screen', authenticated_as: false do
        visit "#organization/profile/#{organization.id}"

        expect(page).to have_css('#login')
      end
    end
  end

  describe 'Core Workflow' do
    include_examples 'core workflow' do
      let(:object_name) { 'Organization' }
      let(:before_it) do
        lambda {
          ensure_websocket(check_if_pinged: false) do
            visit "#organization/profile/#{organization.id}"
            within(:active_content) do
              page.find('.profile .js-action').click
              page.find('.profile li[data-type=edit]').click
            end
          end
        }
      end
    end
  end
end
