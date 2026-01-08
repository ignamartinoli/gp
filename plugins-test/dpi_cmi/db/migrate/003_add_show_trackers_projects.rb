class AddShowTrackersProjects < ActiveRecord::Migration
  def change
  	add_column :projects, :cmi_show_trackers, :string
  end
end