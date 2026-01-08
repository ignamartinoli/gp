# frozen_string_literal: true
# Oculta de “Ficheros” los adjuntos que pertenecen al CF múltiple
# (los marcados con description: 'custom_field:multiple_attachments')

Deface::Override.new(
  virtual_path: 'issues/_attachments',
  name: 'rmacf-filter-out-cf-attachments',
  replace: "erb[loud]:contains('@issue.attachments')",
  text: <<-'ERB'
    <% filtered_attachments =
         @issue.attachments.reject { |a| a.description.to_s.start_with?('custom_field:multiple_attachments') } %>

    <% if filtered_attachments.any? %>
      <%= render partial: 'attachments/links',
                 locals: { attachments: filtered_attachments,
                           options: { deletable: User.current.allowed_to?(:delete_attachments, @project) } } %>
    <% end %>
  ERB
)
