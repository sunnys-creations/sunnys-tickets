# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::PublicLinksControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.public_links')
end
