# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Error handling', type: :request do

  shared_examples 'JSON response format' do

    let(:expected_type) { 'application/json' }

    it { expect(response).to have_http_status(http_status) }
    it { expect(json_response).to be_a(Hash) }

    it do
      # There is a special case where we mask technical errors and return
      # a random error code that can be easily found in the logs by an
      # administrator. However, this makes it hard to check for the exact error
      # message. Therefore we only check for the substring in this particular case
      if message == 'Please contact your administrator' || message == 'Mysql2::Error' || message == 'PG::ForeignKeyViolation'
        expect(json_response['error']).to include(message)
      else
        expect(json_response['error']).to eq(message)
      end
    end
  end

  shared_examples 'HTML response format' do
    let(:expected_type) { 'text/html' }

    it { expect(response).to have_http_status(http_status) }
    it { expect(response.content_type).to start_with('text/html') }
    it { expect(response.body).to include('<html') }
    it { expect(response.body).to include("<title>#{title}</title>") }
    it { expect(response.body).to match("<h1[^>]*>#{headline}</h1>") }
    it { expect(response.body).to include(CGI.escapeHTML(message)) }
  end

  context 'URL route does not exist' do

    before do
      get url, headers: { 'Accept' => expected_type }
    end

    let(:url)         { '/not_existing_url' }
    let(:message)     { "This page doesn't exist." }
    let(:http_status) { :not_found }

    context 'requesting JSON' do
      include_examples 'JSON response format'
    end

    context 'requesting HTML' do
      let(:title) { '404: Not Found' }
      let(:headline) { '404: Requested resource was not found' }

      include_examples 'HTML response format'

      context 'when request ends with URL' do

        let(:url) { '//////this__website__is__closed__visit__our__new__site:_someother.com' }

        include_examples 'HTML response format'
      end
    end
  end

  context 'request is not authenticated' do

    before do
      stub_const('Auth::BRUTE_FORCE_SLEEP', 0)
      authenticated_as(create(:agent), password: 'wrongpw')
      get '/api/v1/organizations', headers: { 'Accept' => expected_type }
    end

    let(:message)     { 'Invalid BasicAuth credentials' }
    let(:http_status) { :unauthorized }

    context 'requesting JSON' do
      include_examples 'JSON response format'
    end

    context 'requesting HTML' do
      let(:title) { '401: Unauthorized' }
      let(:headline) { '401: Unauthorized' }

      include_examples 'HTML response format'
    end
  end

  context 'request is forbidden' do

    before do
      get '/api/v1/organizations', headers: { 'Accept' => expected_type }
    end

    let(:message) { 'Authentication required' }
    let(:http_status) { :forbidden }

    context 'requesting JSON' do
      include_examples 'JSON response format'
    end

    context 'requesting HTML' do
      let(:title) { '403: Forbidden' }
      let(:headline) { '403: Forbidden' }

      include_examples 'HTML response format'
    end
  end

  context 'exception is raised' do
    let(:origin) { 'tests' }

    before do
      authenticated_as(create(user))
      get '/tests/raised_exception', params: { origin: origin, exception: exception.name, message: message }, headers: { 'Accept' => expected_type }
    end

    shared_examples 'exception check' do |message, exception, http_status, title, headline|

      context "#{exception} is raised" do

        let(:exception)   { exception }
        let(:http_status) { http_status }
        let(:message)     { message }

        context 'requesting JSON' do
          include_examples 'JSON response format'
        end

        context 'requesting HTML' do
          let(:title) { title }
          let(:headline) { headline }

          include_examples 'HTML response format'
        end
      end
    end

    shared_examples 'handles exception' do |exception, http_status, title, headline, message = 'some error message'|
      include_examples 'exception check', message, exception, http_status, title, headline
    end

    shared_examples 'masks exception' do |exception, http_status, title, headline|
      include_examples 'exception check', 'Please contact your administrator', exception, http_status, title, headline
    end

    context 'with agent user' do

      let(:user) { :agent }

      include_examples 'handles exception', Exceptions::NotAuthorized, :unauthorized, '401: Unauthorized', '401: Unauthorized'
      include_examples 'handles exception', Exceptions::Forbidden, :forbidden, '403: Forbidden', '403: Forbidden'
      include_examples 'handles exception', Pundit::NotAuthorizedError, :forbidden, '403: Forbidden', '403: Forbidden', 'Not authorized'
      include_examples 'handles exception', ActiveRecord::RecordNotFound, :not_found, '404: Not Found', '404: Requested resource was not found'
      include_examples 'handles exception', Exceptions::UnprocessableEntity, :unprocessable_entity, '422: Unprocessable Entity', '422: The change you wanted was rejected.'
      include_examples 'masks exception', ArgumentError, :unprocessable_entity, '422: Unprocessable Entity', '422: The change you wanted was rejected.'
      include_examples 'masks exception', StandardError, :internal_server_error, '500: An unknown error occurred', '500: An unknown error occurred.'
    end

    context 'with admin user' do

      let(:user) { :admin }

      include_examples 'handles exception', Exceptions::NotAuthorized, :unauthorized, '401: Unauthorized', '401: Unauthorized'
      include_examples 'handles exception', Exceptions::Forbidden, :forbidden, '403: Forbidden', '403: Forbidden'
      include_examples 'handles exception', Pundit::NotAuthorizedError, :forbidden, '403: Forbidden', '403: Forbidden', 'Not authorized'
      include_examples 'handles exception', ActiveRecord::RecordNotFound, :not_found, '404: Not Found', '404: Requested resource was not found'
      include_examples 'handles exception', Exceptions::UnprocessableEntity, :unprocessable_entity, '422: Unprocessable Entity', '422: The change you wanted was rejected.'
      include_examples 'handles exception', ArgumentError, :unprocessable_entity, '422: Unprocessable Entity', '422: The change you wanted was rejected.'
      include_examples 'handles exception', StandardError, :internal_server_error, '500: An unknown error occurred', '500: An unknown error occurred.'
    end

    context 'with mobile controller' do

      let(:origin) { 'mobile' }

      context 'with agent user' do

        let(:user) { :agent }

        include_examples 'handles exception', Exceptions::NotAuthorized, :unauthorized, '401: Unauthorized', '401'
        include_examples 'handles exception', Exceptions::Forbidden, :forbidden, '403: Forbidden', '403'
        include_examples 'handles exception', Pundit::NotAuthorizedError, :forbidden, '403: Forbidden', '403', 'Not authorized'
        include_examples 'handles exception', ActiveRecord::RecordNotFound, :not_found, '404: Not Found', '404'
        include_examples 'handles exception', Exceptions::UnprocessableEntity, :unprocessable_entity, '422: Unprocessable Entity', '422'
        include_examples 'masks exception', ArgumentError, :unprocessable_entity, '422: Unprocessable Entity', '422'
        include_examples 'masks exception', StandardError, :internal_server_error, '500: An unknown error occurred', '500'
      end

      context 'with admin user' do

        let(:user) { :admin }

        include_examples 'handles exception', Exceptions::NotAuthorized, :unauthorized, '401: Unauthorized', '401'
        include_examples 'handles exception', Exceptions::Forbidden, :forbidden, '403: Forbidden', '403'
        include_examples 'handles exception', Pundit::NotAuthorizedError, :forbidden, '403: Forbidden', '403', 'Not authorized'
        include_examples 'handles exception', ActiveRecord::RecordNotFound, :not_found, '404: Not Found', '404'
        include_examples 'handles exception', Exceptions::UnprocessableEntity, :unprocessable_entity, '422: Unprocessable Entity', '422'
        include_examples 'handles exception', ArgumentError, :unprocessable_entity, '422: Unprocessable Entity', '422'
        include_examples 'handles exception', StandardError, :internal_server_error, '500: An unknown error occurred', '500'
      end
    end
  end
end
