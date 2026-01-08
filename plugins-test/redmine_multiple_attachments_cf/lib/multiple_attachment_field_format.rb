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

	  # === AQUÍ pintamos el control dentro del formulario del issue ===
	  # Esto se renderiza en la celda derecha del CF, alineado al resto.
	  def edit_tag(view, tag_id, tag_name, custom_value, options={})
	    issue = view.instance_variable_get(:@issue)
	    cf    = custom_value.custom_field          # <- el CustomField real
	    raw   = custom_value.value.to_s            # <- valor actual como "1,2,3"

	    view.render(
	      partial: 'custom_fields/multiple_attachment_input',
	      locals: {
	        cf: cf,                # el CustomField (para cf.id)
	        issue: issue,
	        tag_id: tag_id,
	        tag_name: tag_name,
	        value: raw             # pasamos el string "1,2,3" a la vista
	      }
	   )
	  end
	  
	  # Si no querés soportar edición masiva, devolvé vacío
	  def bulk_edit_tag(view, tag_id, tag_name, custom_field, projects=nil)
	    ''.html_safe
	  end

	  # --- Conversión/validación del valor ---
	  # Devuelve siempre un array de IDs (enteros)
	  def cast_value(custom_field, value, customized = nil)
	    case value
	    when Array
	      value.map(&:to_i).reject(&:zero?)
	    when String
	      value.split(',').map(&:strip).map(&:to_i).reject(&:zero?)
	    else
	      []
	    end
	  end

	  # Renderiza "nombres con link" como adjuntos normales
	  def formatted_value(view, value, customized=nil, html=false, *args)
	    raw = value.respond_to?(:value) ? value.value : value
	    ids = raw.to_s.split(',').map(&:strip).reject(&:blank?)
	    return ''.html_safe if ids.empty?

	    atts    = Attachment.where(id: ids).index_by { |a| a.id.to_s }
	    ordered = ids.map { |i| atts[i] }.compact

	    if html && view
	      # separador por comas como en los adjuntos nativos
	      links = ordered.map { |a| view.link_to_attachment(a, download: false) }
	      return view.respond_to?(:safe_join) ? view.safe_join(links, ', ') : links.join(', ')
	    else
	      return ordered.map(&:filename).join(', ')
	    end
	  end

	  def validate_single_value(custom_field, value, customized = nil)
	    return [] if value.blank?
	    value.to_s =~ /\A\s*\d+(\s*,\s*\d+)*\s*\z/ ? [] : [::I18n.t(:invalid)]
	  end
	end

  end
end
