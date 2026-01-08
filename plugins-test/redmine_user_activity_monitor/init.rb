require_relative 'lib/redmine_user_activity_monitor'

Redmine::Plugin.register :redmine_user_activity_monitor do
  name 'User Activity Monitor'
  author 'Agustín Liendo'
  description 'Plugin para monitorear la actividad de los usuarios en Redmine'
  version '0.1.0'
  
  settings default: { 'max_rows' => 100 }, partial: 'settings/user_activity_monitor'

  menu :admin_menu,
       :user_activity_monitor,
       { controller: 'user_activity_monitor', action: 'index' },
       caption: 'Monitor de Actividad',
       html: { class: 'icon icon-user' }
end
