# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition::Today < CoreWorkflow::Condition::Backend
  def match
    value_times.all?(&:today?)
  end
end
