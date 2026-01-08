# plugins/redmine_hide_news_menu/init.rb
require 'redmine'

Redmine::Plugin.register :redmine_hide_news_menu do
  name        'Hide News Menu'
  author      'Agustín + ChatGPT'
  description 'Oculta el ítem "Noticias" del menú de proyecto (y el global si existe).'
  version     '0.1.0'
  requires_redmine version_or_higher: '4.0.0'
end

# Borramos el ítem de menú. Lo envolvemos en rescues por compatibilidad entre versiones.
Rails.application.config.to_prepare do
  begin
    Redmine::MenuManager.map :project_menu do |menu|
      menu.delete(:news) rescue nil
    end
  rescue => _e
  end

  begin
    Redmine::MenuManager.map :application_menu do |menu|
      menu.delete(:news) rescue nil
    end
  rescue => _e
  end
end
