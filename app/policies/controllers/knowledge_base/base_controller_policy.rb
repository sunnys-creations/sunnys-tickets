# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::KnowledgeBase::BaseControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('knowledge_base.*')
  permit! %i[create update destroy], to: 'knowledge_base.editor'
end
