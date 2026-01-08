# frozen_string_literal: true
require 'redmine/field_format'

module Redmine
  module FieldFormat
    class MultipleAttachmentFieldFormat < Redmine::FieldFormat::Unbounded
      # Registrar el formato
      add 'multiple_attachment'

      class << self
        # Texto del tipo
        def label; :label_multiple_attachment; end
        # Partial para la pantalla de ADMIN del campo (no para issues)
        def form_partial; 'custom_fields/multiple_attachment_admin'; end
        def searchable_supported; false; end
        def url_allowed; false; end
      end

      # === Control de edición dentro del formulario del issue ===
      # locals esperados en el parcial: cf, issue, tag_id, tag_name, value
      def edit_tag(view, tag_id, tag_name, custom_value, options = {})
        issue = view.instance_variable_get(:@issue)
        cf    = custom_value.custom_field
        raw   = custom_value.value.to_s # "1,2,3"

        view.render(
          partial: 'custom_fields/multiple_attachment_input',
          locals: {
            cf: cf,
            issue: issue,
            tag_id: tag_id,
            tag_name: tag_name,
            value: raw
          }
        )
      end

      # No soportamos edición masiva
      def bulk_edit_tag(view, tag_id, tag_name, custom_field, projects = nil)
        ''.html_safe
      end

      # --- Conversión/validación del valor ---
      # Devuelve siempre un array de IDs (enteros)
      def cast_value(custom_field, value, customized = nil)
        case value
        when Array
          value.map { |v| v.to_i }.reject(&:zero?)
        when String
          value.split(',').map { |s| s.strip }.reject(&:blank?).map(&:to_i)
        else
          []
        end
      end

      # Mostrar en show: lista de enlaces como adjuntos nativos, pero embebidos en la celda del CF
			def formatted_value(view, value, customized=nil, html=false, *args)
				cv = value.is_a?(CustomValue) ? value : nil

				raw =
					if cv
						v = cv.value
						v = v.value if v.respond_to?(:value)
						if (v.blank? || (v.is_a?(Array) && v.compact.empty?)) && cv.id
							v = CustomValue.where(id: cv.id).pluck(:value).first
						end
						v
					else
						value
					end

				ids =
					case raw
					when Array  then raw.map { |x| x.to_s.strip }.reject(&:blank?)
					when String then raw.to_s.split(',').map { |x| x.strip }.reject(&:blank?)
					else []
					end

				# Logs seguros (sin llamar .id sobre algo que puede ser String)
				Rails.logger.info "[RMA-CF] formatted_value raw=#{raw.inspect} ids=#{ids.inspect} html=#{html} customized_class=#{customized.class.name rescue 'n/a'}"

				if ids.empty?
					return html ? "<em>(sin archivos)</em>".html_safe : ""
				end

				atts_by_id = Attachment.where(id: ids.map(&:to_i)).index_by { |a| a.id.to_s }
				ordered    = ids.map { |i| atts_by_id[i] }.compact

				Rails.logger.info "[RMA-CF] formatted_value found=#{ordered.map(&:id)} of #{ids}"

				if ordered.empty?
					fallback = "(IDs: #{ids.join(', ')})"
					return html ? "<em>#{fallback}</em>".html_safe : fallback
				end

								# Si hay una vista disponible, rendereamos SIEMPRE la lista HTML (aunque html == false)
				if view
					items = ordered.map { |a| "<li>#{view.link_to_attachment(a, download: false)}</li>" }
					return "<ul class=\"attachments\">#{items.join}</ul>".html_safe
				end

				# Fallback texto (consola, export, etc.)
				ordered.map(&:filename).join(', ')

			end



      def validate_single_value(custom_field, value, customized = nil)
        return [] if value.blank?
        value.to_s =~ /\A\s*\d+(\s*,\s*\d+)*\s*\z/ ? [] : [::I18n.t(:invalid)]
      end
    end
  end
end
