# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::UserAccessTokenControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('user_preferences.access_token')
end
