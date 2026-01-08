class CreateEspecialidad < ActiveRecord::Migration[5.2]
  def change
    create_table :especialidades do |t|
      t.string :nombre
      t.integer :codigo
      t.integer :titulacion
      t.integer :activo, default: -> { 1 } 
    end
  end
end
