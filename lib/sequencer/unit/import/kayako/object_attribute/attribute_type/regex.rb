# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Regex < Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Text
  private

  def data_type_specific_options
    super.merge(
      regex: attribute['regular_expression'],
    )
  end
end
