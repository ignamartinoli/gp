class AddShowTrackersToDocxProjects < ActiveRecord::Migration
  def change
  	add_column :projects, :cmi_show_trackers_to_docx, :string
  end
end