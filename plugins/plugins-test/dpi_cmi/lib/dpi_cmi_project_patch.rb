module DpiCmiProjectPatch
  def self.included(base)
  	base.send(:include, InstanceMethods)
    base.class_eval do
      # unloadable

      serialize :cmi_versions, Array
      serialize :cmi_show_trackers, Array
      serialize :cmi_show_trackers_to_docx, Array
      serialize :cmi_trackers_con_peso, Array
      safe_attributes :cmi_versions, :perspectiva_cf, :cmi_show_trackers, :cmi_show_subprojects_tasks, :cmi_show_trackers_to_docx,
                      :cmi_trackers_con_peso, :cmi_validar_fecha_inicio_indicadores, :cmi_reports
    end
  end

  module InstanceMethods

  	def puede_generar_reporte?(tracker_id)
  		if self.cmi_show_trackers_to_docx.include?(tracker_id)
  			return true
  		elsif !self.parent.nil? && self.parent.puede_generar_reporte?(tracker_id)
  			return true
  		else
  			return false
  		end
  	end
  end
end
