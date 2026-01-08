class AddVersionPrevistaProjects < ActiveRecord::Migration
  def change
  	add_column :projects, :cmi_versions, :string
  end
end
