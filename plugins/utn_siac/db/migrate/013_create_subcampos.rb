class CreateSubcampos < ActiveRecord::Migration[5.2]
  def change
    create_table :subcampos do |t|
      t.bigint :campo_id, null: false
      t.bigint :tipo_campo_id
      t.string :pregunta, null: false
      t.text :descripcion
      t.integer :obligatorio, default: 0
      t.integer :tiene_pregunta_orientadora, default: 0
      t.integer :permite_adjuntos, default: 0
      t.integer :activo, default: 1
      t.integer :posicion, null: true
      t.timestamps
    end

    add_index :subcampos, :campo_id
    add_index :subcampos, [:campo_id, :posicion], unique: true

    add_foreign_key :subcampos, :campos, column: :campo_id
    add_foreign_key :subcampos, :tipos_campo, column: :tipo_campo_id
  end
end
