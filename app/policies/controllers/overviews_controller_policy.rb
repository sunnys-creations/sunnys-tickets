# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::OverviewsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.overview')
end
