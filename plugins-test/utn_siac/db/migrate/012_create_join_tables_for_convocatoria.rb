class CreateJoinTablesForConvocatoria < ActiveRecord::Migration[5.2]
  def change
    # Crear la tabla de unión para convocatorias y sedes
    create_table :convocatorias_sedes do |t|
      # Usamos las columnas adecuadas para las claves foráneas
      t.bigint :convocatoria_id, null: false
      t.bigint :sede_id, null: false

      # Definir las claves foráneas
      t.foreign_key :convocatorias, column: :convocatoria_id
      t.foreign_key :sedes, column: :sede_id

      # Crear el índice
      t.index [:convocatoria_id, :sede_id], name: 'index_convocatoria_sedes'
    end

   # Crear la tabla de unión para convocatorias y componentes
    create_table :convocatorias_componentes do |t|
      # Usamos las columnas adecuadas para las claves foráneas
      t.bigint :convocatoria_id, null: false
      t.bigint :componente_id, null: false

      # Definir las claves foráneas
      t.foreign_key :convocatorias, column: :convocatoria_id
      t.foreign_key :componentes, column: :componente_id

      # Crear el índice
      t.index [:convocatoria_id, :componente_id], name: 'index_convocatoria_componentes'
    end


    # Crear la tabla de unión para convocatorias y especialidades
    create_table :convocatorias_especialidades do |t|
      # Usamos las columnas adecuadas para las claves foráneas
      t.bigint :convocatoria_id, null: false
      t.bigint :especialidad_id, null: false

      # Definir las claves foráneas
      t.foreign_key :convocatorias, column: :convocatoria_id
      t.foreign_key :especialidades, column: :especialidad_id

      # Crear el índice
      t.index [:convocatoria_id, :especialidad_id], name: 'index_convocatoria_especialidades'
    end
  end
end
