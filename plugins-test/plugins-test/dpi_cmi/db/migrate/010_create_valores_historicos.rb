class CreateValoresHistoricos < ActiveRecord::Migration
  def change
    create_table :historic_values do |t|
      t.references :issue
      t.integer :valor
      t.date :fecha
    end
    add_index :historic_values, :issue_id
  end
end
