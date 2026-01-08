# plugins/redmine_cf_modifications/lib/custom_field_name_patch.rb
module CustomFieldNamePatch
  extend ActiveSupport::Concern

  included do
    # 1. Eliminar SOLO la validación de longitud con máximo 30
    _validators[:name].delete_if do |v|
      v.is_a?(ActiveModel::Validations::LengthValidator) &&
        v.options[:maximum] == 30
    end

    _validate_callbacks.each do |callback|
      if callback.raw_filter.is_a?(ActiveModel::Validations::LengthValidator) &&
         callback.raw_filter.attributes.include?(:name) &&
         callback.raw_filter.options[:maximum] == 30
        _validate_callbacks.delete(callback)
      end
    end

    # 2. Agregar la nueva
    validates_length_of :name, maximum: 50
  end
end

Rails.application.config.to_prepare do
  CustomField.include(CustomFieldNamePatch)
end
