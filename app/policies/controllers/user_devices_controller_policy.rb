# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::UserDevicesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('user_preferences.device')
end
