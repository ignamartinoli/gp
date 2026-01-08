Redmine::Plugin.register :redmine_docx_preview do
  name 'Redmine Docx Preview'
  author 'Team DESA'
  description 'Convierte DOCX a PDF para previsualización con redmine_preview_pdf'
  version '0.1.0'
  requires_redmine version_or_higher: '4.0.3'
end

require_relative 'patches/attachments_controller_patch'

Rails.application.config.to_prepare do
  AttachmentsController.include RedmineDocxPreview::AttachmentsControllerPatch
end