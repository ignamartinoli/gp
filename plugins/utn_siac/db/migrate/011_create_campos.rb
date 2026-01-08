class CreateCampos < ActiveRecord::Migration[5.2]
  def change
    create_table :campos do |t|
      t.references :componente, foreign_key: { to_table: :componentes }
      t.references :tipo_campo, foreign_key: { to_table: :tipos_campo }
      t.integer :tiene_pregunta_orientadora, default: -> { 1 }
      t.text :pregunta
      t.text :descripcion
      t.integer :obligatorio
      t.integer :permite_adjuntos, default: -> { 0 }
      t.integer :subcampo, default: -> { 0 }
      t.references :subcampo_de, foreign_key: { to_table: :campos, on_delete: :nullify }, index: true, null: true, type: :bigint
      t.integer :autoevaluacion, default: -> { 0 }
      t.integer :activo, default: -> { 1 } 

      t.datetime :created_at, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.datetime :updated_at, default: -> { 'CURRENT_TIMESTAMP' }, null: false

      # Si quieres que updated_at se actualice automáticamente en cada UPDATE
      t.datetime :updated_at, default: -> { 'CURRENT_TIMESTAMP' }, null: false, on_update: -> { 'CURRENT_TIMESTAMP' }
    end
  end
end
