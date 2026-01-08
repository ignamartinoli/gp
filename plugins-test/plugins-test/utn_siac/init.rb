Redmine::Plugin.register :utn_siac do
  name 'UTN SIAC'
  author 'TEAM DESA'
  description 'Plugin desarrollado para el area de planeamiento de la Universidad Técnologica Nacional'
  version '1.0.4'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'



  menu :application_menu, :utn_siac, { controller: 'convocatoria', action: 'index' }, caption: 'SIAC', before: :gantt

  Rails.application.config.assets.precompile += %w(especialidades.js)
end
