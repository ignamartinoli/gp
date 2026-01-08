Redmine::Plugin.register :utn_mailing do
  name 'UTN Mailing Plugin'
  author 'Team Desa'
  description 'Plugin para personalizar las plantillas de mails de GP - Redmine'
  version '0.1.0'
  requires_redmine version_or_higher: '4.0.3'

  Rails.configuration.to_prepare do
    require_dependency 'mailer'
    require_dependency 'utn_mailing/mailer_patch'
    Mailer.prepend(UtnMailing::MailerPatch)
  end
end
