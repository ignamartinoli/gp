class UserActivityHookListener < Redmine::Hook::Listener
  def controller_issues_new_after_save(context = {})
    issue = context[:issue]
    UserActivityLogger.record(User.current, "creó issue", issue, issue.subject)
  end

  def controller_issues_edit_after_save(context = {})
    issue = context[:issue]
    UserActivityLogger.record(User.current, "editó issue", issue, issue.subject)
  end

  def controller_timelog_edit_before_save(context = {})
    time_entry = context[:time_entry]
    action = time_entry.new_record? ? "registró horas" : "editó horas"
    UserActivityLogger.record(User.current, action, time_entry, "#{time_entry.hours}h en ##{time_entry.issue_id}")
  end

  def controller_journals_new_after_save(context = {})
    journal = context[:journal]
    UserActivityLogger.record(User.current, "comentó", journal.journalized, journal.notes)
  end
end
