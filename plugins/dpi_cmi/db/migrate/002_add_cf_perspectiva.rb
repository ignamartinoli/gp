class AddCfPerspectiva < ActiveRecord::Migration
  def self.up
    add_column :projects, :perspectiva_cf, :integer
  end

  def self.down
    remove_column :projects, :perspectiva_cf
  end
end
