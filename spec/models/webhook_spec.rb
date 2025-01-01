# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_xss_sanitized_note_examples'

RSpec.describe Webhook, type: :model do

  it_behaves_like 'HasXssSanitizedNote', model_factory: :webhook

  describe 'check endpoint' do
    subject(:webhook) { build(:webhook, endpoint: endpoint) }

    before { webhook.valid? }

    let(:endpoint_errors) { webhook.errors.messages[:endpoint] }

    context 'with missing http type' do
      let(:endpoint) { 'example.com' }

      it { is_expected.not_to be_valid }

      it 'has an error' do
        expect(endpoint_errors).to include 'The provided endpoint is invalid, no http or https protocol was specified.'
      end
    end

    context 'with spaces in invalid hostname' do
      let(:endpoint) { 'http://   example.com' }

      it { is_expected.not_to be_valid }

      it 'has an error' do
        expect(endpoint_errors).to include 'The provided endpoint is invalid.'
      end
    end

    context 'with ? in hostname' do
      let(:endpoint) { 'http://?example.com' }

      it { is_expected.not_to be_valid }

      it 'has an error' do
        expect(endpoint_errors).to include 'The provided endpoint is invalid, no hostname was specified.'
      end
    end

    context 'with nil in endpoint' do
      let(:endpoint) { nil }

      it { is_expected.not_to be_valid }

      it 'has an error' do
        expect(endpoint_errors).to include 'The provided endpoint is invalid.'
      end
    end

    context 'with a valid endpoint' do
      let(:endpoint) { 'https://example.com/endpoint' }

      it { is_expected.to be_valid }

      it 'has no errors' do
        expect(endpoint_errors).to be_empty
      end
    end
  end

  describe 'check custom payload' do
    subject(:webhook) { build(:webhook, custom_payload: custom_payload) }

    before { webhook.valid? }

    let(:custom_payload_errors) { webhook.errors.messages[:custom_payload] }

    context 'with valid JSON' do
      let(:custom_payload) { '{"foo": "bar"}' }

      it { is_expected.to be_valid }

      it 'has no errors' do
        expect(custom_payload_errors).to be_empty
      end
    end

    context 'with invalid JSON' do
      let(:custom_payload) { '{"foo": bar}' }

      it { is_expected.not_to be_valid }

      it 'has an error' do
        expect(custom_payload_errors).to include 'The provided payload is invalid. Please check your syntax.'
      end
    end
  end

  describe 'reset custom payload' do
    subject(:webhook) { create(:webhook, customized_payload: customized_payload, custom_payload: custom_payload) }

    context 'with customized payload' do
      let(:customized_payload) { true }
      let(:custom_payload)     { '{"foo": "bar"}' }

      it 'saves custom payload' do
        expect(webhook).to have_attributes(
          customized_payload: customized_payload,
          custom_payload:     custom_payload,
        )
      end
    end

    context 'without customized payload' do
      let(:customized_payload) { false }
      let(:custom_payload)     { '{"foo": "bar"}' }

      it 'resets custom payload' do
        expect(webhook).to have_attributes(
          customized_payload: customized_payload,
          custom_payload:     nil,
        )
      end
    end
  end

  describe 'check preferences' do
    subject(:webhook) { build(:webhook, preferences: preferences) }

    let(:preferences) { { pre_defined: { class_name: 'Webhook::PreDefined::Example' } } }

    it 'has preferences' do
      expect(webhook.preferences).to include({ 'pre_defined' => { 'class_name' => 'Webhook::PreDefined::Example' } })
    end
  end

  describe '#destroy' do
    subject(:webhook) { create(:webhook) }

    context 'when no dependencies' do
      it 'removes the object' do
        expect { webhook.destroy }.to change(webhook, :destroyed?).to true
      end
    end

    context 'when related object exists' do
      let!(:trigger) { create(:trigger, perform: { 'notification.webhook' => { 'webhook_id' => webhook.id.to_s } }) }

      it 'raises error with details' do
        expect { webhook.destroy }.to raise_error(Exceptions::UnprocessableEntity, %r{#{Regexp.escape("Trigger: #{trigger.name} (##{trigger.id})")}})
      end
    end
  end
end
