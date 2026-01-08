module UserActivityLogger
  def self.record(user, action, target, details = nil)
    UserActivity.create!(
      user: user,
      action: action,
      target_type: target.class.name,
      target_id: target.id,
      details: details,
      created_at: Time.current
    )
  end
end
