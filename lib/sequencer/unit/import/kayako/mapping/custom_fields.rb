# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Mapping::CustomFields < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  uses :resource, :field_map, :model_class, :default_language

  def process
    provide_mapped do
      custom_fields || {}
    end
  end

  private

  def custom_fields
    resource['custom_fields']&.each_with_object({}) do |item, result|
      field = item['field']
      local_name = custom_fields_map[field['key']]

      next if local_name.nil? || item['value'].empty?

      field_type_instance = attribute_type_instance(field)

      result[ local_name.to_sym ] = local_value(local_name, field_type_instance, item['value'])
    end
  end

  def local_value(local_name, field_type_instance, value)
    begin
      field_type_instance.local_value(value)
    rescue => e
      logger.error "Error when setting local value for custom field (#{local_name}) for case: #{resource['id']}."
      logger.error e

      nil
    end
  end

  def custom_fields_map
    @custom_fields_map ||= field_map[model_class.name]
  end

  def attribute_type_instance(field)
    "Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::#{field['type'].capitalize}".constantize.new(field, default_language)
  rescue
    nil
  end
end
