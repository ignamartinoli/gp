class CreateTiposCampo < ActiveRecord::Migration[5.2]
  def change
    create_table :tipos_campo do |t|
      t.string :nombre
      t.text :descripcion
      t.integer :activo, default: -> { 1 } 

      t.datetime :created_at, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.datetime :updated_at, default: -> { 'CURRENT_TIMESTAMP' }, null: false

      # Si quieres que updated_at se actualice automáticamente en cada UPDATE
      t.datetime :updated_at, default: -> { 'CURRENT_TIMESTAMP' }, null: false, on_update: -> { 'CURRENT_TIMESTAMP' }
    end
  end
end
