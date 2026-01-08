class UserActivityMonitorController < ApplicationController
  before_action :require_admin

  def index
    @limit = Setting.plugin_redmine_user_activity_monitor['max_rows'].to_i || 100
    @activities = UserActivity.recent(@limit)
  end
end
