Redmine::Plugin.register :redmine_hide_cf_attachments do
  name 'Redmine Hide Custom Field Attachments'
  author 'Agustín Liendo'
  description 'Oculta los adjuntos de campos personalizados en la sección de archivos de la vista de ticket'
  version '0.0.1'
end

Rails.configuration.to_prepare do
  require_dependency 'issue'
  Issue.send(:include, RedmineHideCfAttachments::IssuePatch) unless Issue.included_modules.include?(RedmineHideCfAttachments::IssuePatch)
end