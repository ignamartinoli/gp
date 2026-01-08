class CreateSedes < ActiveRecord::Migration[5.2]
  def change
    create_table :sedes do |t|
      t.string :nombre
      t.integer :regional
      t.integer :codigo
      t.integer :activo, default: -> { 1 } 
    end
  end
end
