class CreateJoinTablesForEspecialidad < ActiveRecord::Migration[5.2]
  def change
    # Crear la tabla de unión para especialidades y sedes
    create_table :especialidades_sedes do |t|
      # Usamos las columnas adecuadas para las claves foráneas
      t.bigint :especialidad_id, null: false
      t.bigint :sede_id, null: false
      t.integer :activo, default: -> { 1 } 

      # Definir las claves foráneas explícitas
      t.foreign_key :especialidades, column: :especialidad_id
      t.foreign_key :sedes, column: :sede_id

      # Crear el índice
      t.index [:especialidad_id, :sede_id], name: 'index_especialidades_sedes'
    end
  end
end
