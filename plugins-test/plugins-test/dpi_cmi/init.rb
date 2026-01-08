require 'redmine'
require 'semaphore_hooks'
require 'dpi_cmi_issues_hooks'
require 'imgkit'

ActiveSupport::Reloader.to_prepare do
  begin
    require_dependency 'project'
    Project.send(:include, DpiCmiProjectPatch)
    require_dependency 'issue'
    Issue.send(:include, DpiCmiIssuePatch)
    unless ProjectsHelper.included_modules.include?(DpiCmiProjectsHelperPatch)
      # ProjectsHelper.send(:include, DpiCmiProjectsHelperPatch)
      ProjectsHelper.send(:prepend, DpiCmiProjectsHelperPatch)
    end
  rescue => e
    Rails.logger.error "[DPI_CMI] Error cargando parches: #{e.message}"
  end

end

Redmine::Plugin.register :dpi_cmi do
  name 'DPI CMI plugin'
  author 'Area Clave - Developed by BTnet'
  description 'DPI CMI is a Redmine plugin to have a summary of projects management metrics'
  version '0.1.8'
  author_url 'http://www.btnet.com.ar'
  url 'http://www.plandeaccion.com.ar'

  project_module :CMI do
    permission :goals, { goals: [:index] }
    permission :modificar_valores_indicador, { goals: [:index] }
    permission :manage_historic_values, { historic_values: [:index, :new, :edit, :create, :update, :destroy] }
  end

  menu :project_menu, :goals, { controller: 'goals', action: 'index' },
    caption: :'cmi.label_tab',
    after: :activity,
    params: :project_id
end
