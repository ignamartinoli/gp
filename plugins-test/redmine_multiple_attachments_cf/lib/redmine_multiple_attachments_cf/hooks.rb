# frozen_string_literal: true
require_dependency 'application_helper'

module RedmineMultipleAttachmentsCf
  class ViewHooks < Redmine::Hook::ViewListener
    # Inyectar CSS + JS del plugin en <head>
    def view_layouts_base_html_head(_context = {})
      out = +''
      out << stylesheet_link_tag('multiple_attachments_cf', plugin: 'redmine_multiple_attachments_cf')
      out << javascript_include_tag('rmacf', plugin: 'redmine_multiple_attachments_cf') # <<-- TU archivo
      out.html_safe
    end

    module RedmineMultipleAttachmentsCf
      class Hooks < Redmine::Hook::ViewListener
        render_on :view_issues_show_details_bottom, partial: 'hooks/rmacf_fill_show_values'
      end
    end


    # Bloque de lectura en SHOW (tu parcial existente)
    # render_on :view_issues_show_details_bottom, partial: 'hooks/rmacf_show_block'

    # NUEVO: uploader en el formulario de edición
    # render_on :view_issues_form_details_bottom, partial: 'hooks/rmacf_cf_uploader'
  end
end
