module RedmineHideCfAttachments
  class ViewHooks < Redmine::Hook::ViewListener
    render_on :view_issues_show_details_bottom, partial: 'issues/hide_cf_attachments'
  end
end
