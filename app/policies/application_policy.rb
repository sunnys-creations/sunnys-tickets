# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ApplicationPolicy
  include PunditPolicy

  attr_reader :record

  def initialize_context(record)
    @record = record
  end
end
