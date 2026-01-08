# plugins/redmine_multiple_attachments_cf/init.rb

Redmine::Plugin.register :redmine_multiple_attachments_cf do
  name 'Redmine Multiple Attachments Custom Field'
  author 'Agustín Liendo'
  description 'Permite adjuntar múltiples archivos en un campo personalizado'
  version '0.0.1'
end

# Hooks de vistas (si existe uno u otro archivo)
begin
  require_relative 'lib/redmine_multiple_attachments_cf/view_hooks'
rescue LoadError
  begin
    require_relative 'lib/redmine_multiple_attachments_cf/hooks'
  rescue LoadError => e
    Rails.logger.info "[RMA-CF] hooks no cargados: #{e.message}"
  end
end

# Precompilar assets del plugin (opcional)
begin
  Rails.application.config.assets.precompile += %w[multiple_attachments_cf.css multiple_attachments_cf.js]
rescue => e
  Rails.logger.info "[RMA-CF] assets.precompile skip (#{e.class}: #{e.message})"
end

# Cargar FieldFormat ANTES del patch
require 'redmine/field_format'
require_relative 'lib/redmine_multiple_attachments_cf/multiple_attachment_field_format'

# (Opcional) cargar deface overrides si existen
begin
  require_relative 'lib/redmine_multiple_attachments_cf/deface_filter_issue_attachments'
rescue LoadError => e
  Rails.logger.info "[RMA-CF] deface no cargado: #{e.message}"
end

# Aplicar patch con recarga segura
Rails.configuration.to_prepare do
  begin
    require_dependency 'issues_controller'
    require_dependency File.expand_path('app/patches/issues_controller_patch', __dir__)

    mod = RedmineMultipleAttachmentsCf::Patches::IssuesControllerPatch
    unless IssuesController.ancestors.include?(mod)
      IssuesController.prepend mod
      Rails.logger.info "[RMA-CF] patch aplicado a IssuesController"
    end
  rescue => e
    Rails.logger.error "[RMA-CF] Error al aplicar patch: #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.first
  end
end
Rails.configuration.to_prepare do
  require_dependency File.expand_path('lib/redmine_multiple_attachments_cf/patches/attachments_helper_patch', __dir__)
end


Rails.logger.info "[RMA-CF] init.rb OK"
