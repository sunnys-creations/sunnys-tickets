# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Webhook::Message::Video < Whatsapp::Webhook::Message::Media
  private

  def type
    :video
  end
end
