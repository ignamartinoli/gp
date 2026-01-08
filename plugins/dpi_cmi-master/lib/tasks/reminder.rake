desc <<-END_DESC
Send reminders about issues due in the next days.

Available options:
  * days     => number of days to remind about (defaults to 7)
  * tracker  => id of tracker (defaults to all trackers)
  * project  => id or identifier of project (defaults to all projects)
  * users    => comma separated list of user/group ids who should be reminded

Example:
  rake redmine:send_reminders days=7 users="1,23, 56" RAILS_ENV="production"
END_DESC

namespace :cmi do
  task :send_reminders => :environment do
    options = {}
    options[:days] = ENV['days'].to_i if ENV['days']
    options[:project] = ENV['project'] if ENV['project']
    options[:tracker] = ENV['tracker'].to_i if ENV['tracker']
    options[:users] = (ENV['users'] || '').split(',').each(&:strip!)

    Mailer.with_synched_deliveries do
      days = options[:days] || 15
      project = options[:project] ? Project.find(options[:project]) : nil
      tracker = options[:tracker] ? Tracker.find(options[:tracker]) : nil
      user_ids = options[:users]

      if days==0
        scope = Issue.open.where("#{Issue.table_name}.assigned_to_id IS NOT NULL" +
          " AND #{Project.table_name}.status = #{Project::STATUS_ACTIVE}" +
          " AND #{Issue.table_name}.due_date = ?", Date.today
        )
      else
        scope = Issue.open.where("#{Issue.table_name}.assigned_to_id IS NOT NULL" +
          " AND #{Project.table_name}.status = #{Project::STATUS_ACTIVE}" +
          " AND #{Issue.table_name}.due_date = ?", days.day.from_now.to_date
        )
      end
      scope = scope.where(:assigned_to_id => user_ids) if user_ids.present?
      scope = scope.where(:project_id => project.id) if project
      scope = scope.where(:tracker_id => tracker.id) if tracker
      issues_by_assignee = scope.includes(:status, :assigned_to, :project, :tracker).
                                group_by(&:assigned_to)
      issues_by_assignee.keys.each do |assignee|
        if assignee.is_a?(Group)
          assignee.users.each do |user|
            issues_by_assignee[user] ||= []
            issues_by_assignee[user] += issues_by_assignee[assignee]
          end
        end
      end
      issues_by_assignee.each do |assignee, issues|
        Mailer.reminder(assignee, issues, days).deliver if assignee.is_a?(User) && assignee.active?
      end

    end

  end
end