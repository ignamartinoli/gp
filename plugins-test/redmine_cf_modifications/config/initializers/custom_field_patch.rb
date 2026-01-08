# plugins/redmine_cf_modifications/config/initializers/custom_field_patch.rb
Rails.application.config.to_prepare do
  CustomField.class_eval do
    # Remueve validaciones previas de :name
    _validators[:name].delete_if do |v|
      v.is_a?(ActiveModel::Validations::LengthValidator)
    end

    # Remueve callbacks viejos también
    _validate_callbacks.each do |cb|
      if cb.raw_filter.is_a?(ActiveModel::Validations::LengthValidator) &&
         cb.raw_filter.options[:maximum] == 30
        _validate_callbacks.delete(cb)
      end
    end

    # Define nuestra nueva validación
    validates_length_of :name, maximum: 50
  end
end
