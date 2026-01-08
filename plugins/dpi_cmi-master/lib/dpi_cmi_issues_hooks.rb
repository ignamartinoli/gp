class DpiCmiIssueHook < Redmine::Hook::ViewListener
 render_on :view_issues_form_details_bottom, :partial => "indicadores/issue_indicadores"
 render_on :view_issues_show_description_bottom, :partial => "indicadores/show_issue_indicadores"
 render_on :view_issues_sidebar_queries_bottom, :partial => "indicadores/show_issue_export_link"
end