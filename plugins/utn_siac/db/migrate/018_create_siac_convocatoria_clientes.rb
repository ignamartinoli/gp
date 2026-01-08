class CreateSiacConvocatoriaClientes < ActiveRecord::Migration[5.2]
  def change
    create_table :siac_convocatoria_clientes do |t|
      t.integer :convocatoria_id, null: false
      t.integer :siac_cliente_id, null: false

      t.timestamps
    end

    add_index :siac_convocatoria_clientes,
              [:convocatoria_id, :siac_cliente_id],
              unique: true,
              name: 'idx_siac_convocatoria_cliente_unique'

    add_index :siac_convocatoria_clientes, :siac_cliente_id
  end
end
