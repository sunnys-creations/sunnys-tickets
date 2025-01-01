# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Ticket::Article::EnqueueCommunicateWhatsappJob
  extend ActiveSupport::Concern

  included do
    after_create :ticket_article_enqueue_communicate_whatsapp_job
  end

  private

  def ticket_article_enqueue_communicate_whatsapp_job

    # return if we run import mode
    return true if Setting.get('import_mode')

    # if sender is customer, do not communicate
    return true if !sender_id

    sender = Ticket::Article::Sender.lookup(id: sender_id)
    return true if sender.nil?
    return true if sender.name == 'Customer'

    # only apply on whatsapp messages
    return true if !type_id

    type = Ticket::Article::Type.lookup(id: type_id)
    return true if type.name != 'whatsapp message'

    CommunicateWhatsappJob.perform_later(id)
  end

end
