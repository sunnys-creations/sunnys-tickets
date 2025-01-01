# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'net/imap'

module ImapHelper
  def imap_delete_old_mails(options)
    imap = ::Net::IMAP.new(options[:host], port: options[:port], ssl: (options[:ssl] ? { verify_mode: OpenSSL::SSL::VERIFY_NONE } : false))
    imap.authenticate(options[:auth_type], options[:user], options[:password])
    imap.select('INBOX')

    message_ids = imap.search(['BEFORE', 1.day.ago.to_date.strftime('%d-%b-%Y')])

    Rails.logger.debug { "#{message_ids.count} messages in INBOX will be deleted!" } if message_ids.count.positive?

    message_ids.each do |message_id|
      imap.store(message_id, '+FLAGS', [:Deleted])
    end
    imap.expunge if message_ids.count.positive?
  end
end

RSpec.configure do |config|
  config.include ImapHelper, integration: true
end
