class AddReportSetting < ActiveRecord::Migration
  def change
  	add_column :projects, :cmi_reports, :boolean, default: false
  end
end
