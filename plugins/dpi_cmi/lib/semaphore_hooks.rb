class SemaphoreHooks < Redmine::Hook::ViewListener
  render_on(:view_layouts_base_html_head, partial: 'hooks/semaphore_css')
end
