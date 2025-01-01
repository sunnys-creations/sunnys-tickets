# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user
    identified_by :sid

    # current_user is stored in the context of GraphQL which is persistent
    #   for the scope of a subscription and cannot be changed from within
    #   other subscriptions.
    # Therefore, on login/logout, a new web socket connection must be made to
    #   reflect the changes within GraphQL.
    def connect
      return if session_id.blank?

      self.current_user = find_verified_user
      self.sid          = session_id
    end

    private

    def find_verified_user
      private_id = Rack::Session::SessionId.new(session_id).private_id

      session = ActiveRecord::SessionStore::Session.find_by(session_id: private_id)
      return if !session

      User.find_by(id: session.data['user_id'])
    end

    def session_id
      @session_id ||= cookies[Zammad::Application::Initializer::SessionStore::SESSION_KEY]
    end
  end
end
