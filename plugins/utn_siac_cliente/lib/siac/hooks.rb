module Siac
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_layouts_base_html_head, partial: 'siac_cliente/hooks'
  end
end
