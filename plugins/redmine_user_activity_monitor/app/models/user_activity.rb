class UserActivity < ActiveRecord::Base
  belongs_to :user

  def self.recent(limit = 100)
    order(created_at: :desc).limit(limit)
  end
end
