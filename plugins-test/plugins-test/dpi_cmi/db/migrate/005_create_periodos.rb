class CreatePeriodos < ActiveRecord::Migration
  def change
    create_table :periodos do |t|
      t.references :issue
      t.integer :periodo
      t.integer :ind_min
      t.integer :ind_med
      t.integer :ind_max
    end
    add_index :periodos, :issue_id
  end
end
