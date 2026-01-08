class CreateComponentes < ActiveRecord::Migration[5.2]
  def change
    create_table :componentes do |t|
      t.references :dimension, foreign_key: { to_table: :dimensiones } # Clave foránea hacia dimensiones
      t.string :nombre
      t.text :descripcion
      t.integer :activo, default: -> { 1 } 

      t.timestamps # Agrega created_at y updated_at automáticamente
    end
  end
end
