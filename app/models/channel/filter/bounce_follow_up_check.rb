# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Channel::Filter::BounceFollowUpCheck

  def self.run(_channel, mail, _transaction_params)

    return if !mail[:mail_instance]
    return if !mail[:mail_instance].bounced?
    return if !mail[:attachments]
    return if mail[ :'x-zammad-ticket-id' ]

    mail[:attachments].each do |attachment|
      next if !attachment[:preferences]
      next if attachment[:preferences]['Mime-Type'] != 'message/rfc822'
      next if !attachment[:data]

      result = Channel::EmailParser.new.parse(attachment[:data], allow_missing_attribute_exceptions: false)
      next if !result[:message_id]

      message_id_md5 = Digest::MD5.hexdigest(result[:message_id])
      article = Ticket::Article.where(message_id_md5: message_id_md5).reorder('created_at DESC, id DESC').limit(1).first
      next if !article

      Rails.logger.debug { "Follow-up for '##{article.ticket.number}' in bounce email." }
      mail[ :'x-zammad-ticket-id' ] = article.ticket_id
      mail[ :'x-zammad-is-auto-response' ] = true

      return true
    end

  end
end
