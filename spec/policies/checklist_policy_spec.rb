# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe ChecklistPolicy do
  subject(:policy) { described_class.new(user, record) }

  let(:record) { build(:checklist, ticket: ticket) }
  let(:ticket) { create(:ticket) }
  let(:group)  { ticket.group }
  let(:user)   { create(:agent, groups: [group]) }

  context 'when user does not have access to the ticket' do
    let(:user) { create(:agent) }

    it { is_expected.to forbid_actions(:show, :update, :destroy) }
  end

  context 'when user has read access to the ticket' do
    let(:user) { create(:agent) }

    before { user.user_groups.create! group: ticket.group, access: 'read' }

    it { is_expected.to forbid_actions(:update, :destroy) }
    it { is_expected.to permit_actions(:show) }
  end

  context 'when user has full access to the ticket' do
    let(:user) { create(:agent, groups: [ticket.group]) }

    it { is_expected.to permit_actions(:show, :update, :destroy) }

    context 'when checklist feature is disabled' do
      before do
        Setting.set('checklist', false)
      end

      it { is_expected.to forbid_actions(:show, :update, :destroy) }
    end
  end

  context 'when user has access to the ticket by having customer access' do
    let(:user) { create(:customer) }

    before { ticket.update! customer: user }

    it { is_expected.to forbid_actions(:show, :update, :destroy) }
  end
end
