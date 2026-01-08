class CreateDimensiones < ActiveRecord::Migration[5.2]
  def change
    create_table :dimensiones do |t|
      t.string :dimension
      t.integer :activo, default: -> { 1 } 
    end
  end
end
