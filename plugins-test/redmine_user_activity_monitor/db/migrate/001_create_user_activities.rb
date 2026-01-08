class CreateUserActivities < ActiveRecord::Migration[5.2]
  def change
    create_table :user_activities do |t|
      t.references :user, null: false
      t.string :action
      t.string :target_type
      t.integer :target_id
      t.text :details
      t.datetime :created_at, null: false
    end

    add_index :user_activities, :created_at
  end
end
