# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Form', type: :request do

  describe 'request handling' do

    it 'does get config call' do
      post '/api/v1/form_config', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Not authorized')
    end

    it 'does get config call with form_ticket_create' do
      Setting.set('form_ticket_create', true)
      post '/api/v1/form_config', params: {}, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Not authorized')

    end

    it 'does get config call & do submit' do
      Setting.set('form_ticket_create', true)
      fingerprint = SecureRandom.hex(40)
      post '/api/v1/form_config', params: { fingerprint: fingerprint }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['enabled']).to be(true)
      expect(json_response['endpoint']).to eq('http://zammad.example.com/api/v1/form_submit')
      expect(json_response['token']).to be_truthy
      token = json_response['token']

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: 'invalid' }, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Authorization failed')

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)

      expect(json_response['errors']).to be_truthy
      expect(json_response['errors']['name']).to eq('required')
      expect(json_response['errors']['email']).to eq('required')
      expect(json_response['errors']['title']).to eq('required')
      expect(json_response['errors']['body']).to eq('required')

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, email: 'some' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)

      expect(json_response['errors']).to be_truthy
      expect(json_response['errors']['name']).to eq('required')
      expect(json_response['errors']['email']).to eq('invalid')
      expect(json_response['errors']['title']).to eq('required')
      expect(json_response['errors']['body']).to eq('required')

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: 'test', body: 'hello' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)

      expect(json_response['errors']).to be_falsey
      expect(json_response['ticket']).to be_truthy
      expect(json_response['ticket']['id']).to be_truthy
      expect(json_response['ticket']['number']).to be_truthy

      travel 5.hours

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: 'test', body: 'hello' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)

      expect(json_response['errors']).to be_falsey
      expect(json_response['ticket']).to be_truthy
      expect(json_response['ticket']['id']).to be_truthy
      expect(json_response['ticket']['number']).to be_truthy

      travel 20.hours

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: 'test', body: 'hello' }, as: :json
      expect(response).to have_http_status(:unauthorized)

    end

    it 'does get config call & do submit - second test' do
      Setting.set('form_ticket_create', true)
      fingerprint = SecureRandom.hex(40)
      post '/api/v1/form_config', params: { fingerprint: fingerprint }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response['enabled']).to be(true)
      expect(json_response['endpoint']).to eq('http://zammad.example.com/api/v1/form_submit')
      expect(json_response['token']).to be_truthy
      token = json_response['token']

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: 'invalid' }, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Authorization failed')

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)

      expect(json_response['errors']).to be_truthy
      expect(json_response['errors']['name']).to eq('required')
      expect(json_response['errors']['email']).to eq('required')
      expect(json_response['errors']['title']).to eq('required')
      expect(json_response['errors']['body']).to eq('required')

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, email: 'some' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)

      expect(json_response['errors']).to be_truthy
      expect(json_response['errors']['name']).to eq('required')
      expect(json_response['errors']['email']).to eq('invalid')
      expect(json_response['errors']['title']).to eq('required')
      expect(json_response['errors']['body']).to eq('required')

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'somebody@somedomainthatisinvalid.com', title: 'test', body: 'hello' }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)

      expect(json_response['errors']).to be_truthy
      expect(json_response['errors']['email']).to eq('invalid')

    end

    it 'does limits', :rack_attack do
      Setting.set('form_ticket_create_by_ip_per_hour', 2)
      Setting.set('form_ticket_create', true)
      fingerprint = SecureRandom.hex(40)

      post '/api/v1/form_config', params: { fingerprint: fingerprint }, as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response['token']).to be_truthy
      token = json_response['token']

      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: 'test', body: 'hello' }, as: :json
      expect(response).to have_http_status(:ok)

      3.times do |count|
        post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: "test#{count}", body: 'hello' }, as: :json
      end
      expect(response).to have_http_status(:too_many_requests)

      @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json', 'REMOTE_ADDR' => '1.2.3.5' }
      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: 'test-2', body: 'hello' }, as: :json
      expect(response).to have_http_status(:ok)

      3.times do |count|
        post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: "test-2-#{count}", body: 'hello' }, as: :json
      end
      expect(response).to have_http_status(:too_many_requests)

      @headers = { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json', 'REMOTE_ADDR' => '::1' }
      post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: 'test-3', body: 'hello' }, as: :json

      3.times do |count|
        post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: "test-3-#{count}", body: 'hello' }, as: :json
      end
      expect(response).to have_http_status(:too_many_requests)
    end

    it 'does customer_ticket_create false disables form' do
      Setting.set('form_ticket_create', false)
      Setting.set('customer_ticket_create', true)

      fingerprint = SecureRandom.hex(40)

      post '/api/v1/form_config', params: { fingerprint: fingerprint }, as: :json

      token = json_response['token']
      params = {
        fingerprint: fingerprint,
        token:       token,
        name:        'Bob Smith',
        email:       'discard@zammad.com',
        title:       'test',
        body:        'hello'
      }

      post '/api/v1/form_submit', params: params, as: :json

      expect(response).to have_http_status(:forbidden)
    end

    context 'when ApplicationHandleInfo context' do
      let(:fingerprint) { SecureRandom.hex(40) }
      let(:token)       { json_response['token'] }

      before do
        Setting.set('form_ticket_create', true)
        post '/api/v1/form_config', params: { fingerprint: fingerprint }, as: :json
      end

      it 'gets switched to "form"' do
        allow(ApplicationHandleInfo).to receive('context=')
        post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: 'test-last', body: 'hello' }, as: :json
        expect(ApplicationHandleInfo).to have_received('context=').with('form').at_least(1)
      end

      it 'reverts back to default' do
        allow(ApplicationHandleInfo).to receive('context=')
        post '/api/v1/form_submit', params: { fingerprint: fingerprint, token: token, name: 'Bob Smith', email: 'discard@zammad.com', title: 'test-last', body: 'hello' }, as: :json
        expect(ApplicationHandleInfo.context).not_to eq 'form'
      end
    end
  end
end
