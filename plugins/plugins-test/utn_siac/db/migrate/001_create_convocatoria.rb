class CreateConvocatoria < ActiveRecord::Migration[5.2]
  def change
    create_table :convocatorias do |t|
      t.string :resolucion
      t.string :nombre
      t.date :fecha_inicio
      t.date :fecha_hasta
      t.string :titulaciones
      t.string :etapa
      t.datetime :fecha_creacion, default: -> { 'CURRENT_TIMESTAMP' } 
      t.string :estado, default: 'Abierta'
    end
  end
end
