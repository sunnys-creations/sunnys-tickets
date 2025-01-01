# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Session, type: :model do

  describe 'Check that session creation' do
    context 'without persistent flag in data payload' do
      subject(:session) { described_class.create(session_id: SecureRandom.urlsafe_base64(64), data: {}) }

      it 'does not set the persistent attribute' do
        expect(session.persistent).to be_nil
      end
    end

    context 'with true persistent flag in data payload' do
      subject(:session) { described_class.create(session_id: SecureRandom.urlsafe_base64(64), data: { 'persistent' => true }) }

      it 'sets the persistent attribute in the session and removes the persistent attribute from the data payload' do
        expect(session.persistent).to be(true)
        expect(session.persistent).to be(true)
      end
    end

    context 'with false persistent flag in data payload' do
      subject(:session) { described_class.create(session_id: SecureRandom.urlsafe_base64(64), data: { 'persistent' => false }) }

      it 'does not set the persistent attribute' do
        expect(session.persistent).to be_nil
      end
    end
  end

end
