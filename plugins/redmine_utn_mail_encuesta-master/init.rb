ActiveSupport::Reloader.to_prepare do
	require_dependency 'issue'
  require 'encuesta_issue_patch/issue_patch'
  unless Issue.included_modules.include?(EncuestaIssuePatch::IssuePatch)
    Issue.send(:include, EncuestaIssuePatch::IssuePatch)
  end
end

Redmine::Plugin.register :redmine_utn_mail_encuesta do
  name 'Redmine Utn Mail Encuesta plugin'
  author 'UTN - TICs'
  description 'Plugin para enviar encuesta al cerrar petición'
  version '0.0.1'
  # url 'http://example.com/path/to/plugin'
  author_url 'http://www.utn.edu.ar'
end
