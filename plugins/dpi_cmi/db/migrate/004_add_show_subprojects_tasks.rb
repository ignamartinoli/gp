class AddShowSubprojectsTasks < ActiveRecord::Migration
  def change
  	add_column :projects, :cmi_show_subprojects_tasks, :boolean, default: false
  end
end