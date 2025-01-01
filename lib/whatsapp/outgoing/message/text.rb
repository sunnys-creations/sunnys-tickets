# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Outgoing::Message::Text < Whatsapp::Outgoing::Message
  def deliver(body:)
    response = messages_api.send_text(sender_id: phone_number_id.to_i, recipient_number: recipient_number.to_i, message: body)

    handle_error(response:)
    handle_response(response:)
  end
end
