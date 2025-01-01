# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::User::TwoFactor::GetMethodConfiguration < Service::User::TwoFactor::Base
  def execute
    user_preference&.configuration
  end
end
