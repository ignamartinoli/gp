Rails.configuration.to_prepare do
  plugin_root = File.dirname(__FILE__)

  # Autoload
  %w[
    app/models
    app/models/concerns
    lib
  ].each do |path|
    ActiveSupport::Dependencies.autoload_paths << File.join(plugin_root, path)
  end

  # Models y concerns críticos
  require_dependency 'concerns/siac_user'

  # Patches
  require_dependency 'siac_user_patch'
  require_dependency 'siac/application_controller_patch'
  require_dependency 'siac/controller_guard'

  # Patch User
  unless User.included_modules.include?(SiacUser)
    User.send(:include, SiacUser)
  end

  # Patch ApplicationController
  unless ApplicationController.included_modules.include?(Siac::ApplicationControllerPatch)
    ApplicationController.send(:include, Siac::ApplicationControllerPatch)
  end
end



Redmine::Plugin.register :utn_siac do
  name 'UTN SIAC'
  author 'TEAM DESA'
  description 'Plugin desarrollado para el area de planeamiento de la Universidad Técnologica Nacional'
  version '1.0.4'

  menu :application_menu, :utn_siac,
     { controller: 'convocatoria', action: 'index' },
     caption: 'SIAC', before: :gantt,
     if: Proc.new { User.current.logged? && !User.current.siac_cliente? }

  Rails.application.config.assets.precompile += %w(especialidades.js)
end
