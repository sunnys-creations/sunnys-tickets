# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Integration', type: :system do
  before do
    visit '#system/integration'
  end

  describe 'Switching on/off integrations (e.g. LDAP + Exchange) leads to unpredictable results #4181' do
    it 'does not switch on multiple integrations' do
      click_on 'GitHub'
      click_on 'Integrations'
      click_on 'GitLab'
      click '.js-switch'
      click_on 'Integrations'
      expect(page).to have_css('tr[data-key=IntegrationGitLab] .icon-status.ok')
      expect(page).to have_no_css('tr[data-key=IntegrationGitHub] .icon-status.ok')
    end
  end
end
