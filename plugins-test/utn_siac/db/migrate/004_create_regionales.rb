class CreateRegionales < ActiveRecord::Migration[5.2]
  def change
    create_table :regionales do |t|
      t.string :nombre
      t.integer :codigo
      t.integer :tipo
      t.integer :activo, default: -> { 1 } 
    end
  end
end
