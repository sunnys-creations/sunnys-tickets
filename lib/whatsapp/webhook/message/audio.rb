# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Webhook::Message::Audio < Whatsapp::Webhook::Message::Media
  private

  def type
    :audio
  end
end
