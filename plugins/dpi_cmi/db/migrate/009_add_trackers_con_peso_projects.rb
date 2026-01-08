class AddTrackersConPesoProjects < ActiveRecord::Migration
  def change
  	add_column :projects, :cmi_trackers_con_peso, :string
  end
end