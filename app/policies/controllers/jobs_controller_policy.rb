# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::JobsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.scheduler')
end
