# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe UserInfo do

  describe '#current_user_id' do

    it 'is nil by default' do
      expect(described_class.current_user_id).to be_nil
    end

    it 'takes a User ID as paramter and returns it' do
      test_id = 99
      described_class.current_user_id = test_id
      expect(described_class.current_user_id).to eq(test_id)
    end
  end

  describe '#ensure_current_user_id' do

    let(:return_value) { 'Hello World' }

    it 'uses and keeps set User IDs' do
      test_id = 99
      described_class.current_user_id = test_id

      described_class.ensure_current_user_id do
        expect(described_class.current_user_id).to eq(test_id)
      end

      expect(described_class.current_user_id).to eq(test_id)
    end

    it 'sets and resets temporary User ID 1' do
      described_class.current_user_id = nil

      described_class.ensure_current_user_id do
        expect(described_class.current_user_id).to eq(1)
      end

      expect(described_class.current_user_id).to be_nil
    end

    it 'resets current_user_id in case of an exception' do
      begin
        described_class.ensure_current_user_id do
          raise 'error'
        end
      rescue # rubocop:disable Lint/SuppressedException
      end

      expect(described_class.current_user_id).to be_nil
    end

    it 'passes return value of given block' do

      received = described_class.ensure_current_user_id do
        return_value
      end

      expect(received).to eq(return_value)
    end

  end

  describe 'with_user_id' do

    let(:return_value) { 'Hello World' }
    let(:test_id)         { 666 }
    let(:another_test_id) { 123 }

    it 'uses given user ID in the given block' do
      described_class.with_user_id(test_id) do
        expect(described_class.current_user_id).to eq(test_id)
      end
    end

    it 'resets to surrounding user ID' do
      described_class.current_user_id = test_id

      described_class.with_user_id(another_test_id) do
        expect(described_class.current_user_id).not_to eq(test_id)
      end

      expect(described_class.current_user_id).to eq(test_id)
    end

    it 'resets current_user_id in case of an exception' do
      begin
        described_class.with_user_id(test_id) do
          raise 'error'
        end
      rescue # rubocop:disable Lint/SuppressedException
      end

      expect(described_class.current_user_id).to be_nil
    end

    it 'passes return value of given block' do
      received = described_class.with_user_id(test_id) do
        return_value
      end

      expect(received).to eq(return_value)
    end

  end
end
