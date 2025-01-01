# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe VersionPolicy do
  subject(:version_policy) { described_class.new(user, nil) }

  let(:user) { create(:user, roles: [role]) }

  context 'with "admin" privileges' do
    let(:role) do
      create(:role).tap { |role| role.permission_grant('admin') }
    end

    it { is_expected.to permit_actions(%i[show]) }
  end

  context 'without "admin" privileges' do
    let(:role) do
      create(:role).tap { |role| role.permission_grant('ticket.agent') }
    end

    it { is_expected.to forbid_actions(%i[show]) }
  end
end
