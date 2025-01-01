# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module ApplicationController::HandlesTransitions
  extend ActiveSupport::Concern

  included do
    around_action :handle_transaction
  end

  private

  def handle_transaction
    ApplicationHandleInfo.current = 'application_server'
    PushMessages.init

    yield

    TransactionDispatcher.commit
    PushMessages.finish
  ensure
    ApplicationHandleInfo.current = nil
  end
end
