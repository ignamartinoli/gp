# plugins/redmine_cf_modifications/init.rb
require 'redmine'

Redmine::Plugin.register :redmine_cf_modifications do
  name 'Redmine CF Modifications'
  author 'Equipo GP'
  description 'Parche para extender nombre de Custom Fields a 50 caracteres'
  version '0.0.2'
end

require_dependency 'custom_field_name_patch'

# Hook visual para inyectar el botón en la UI
class CfModificationsHooks < Redmine::Hook::ViewListener
  render_on :view_custom_fields_form_upper_box, partial: 'cf_modifications/change_type_button'
end

# Inyectar CSS
class CfModificationsAssets < Redmine::Hook::ViewListener
  def view_layouts_base_html_head(_context = {})
    stylesheet_link_tag('cf_modifications', plugin: 'redmine_cf_modifications')
  end
end
