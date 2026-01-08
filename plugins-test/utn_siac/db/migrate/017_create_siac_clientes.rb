class CreateSiacClientes < ActiveRecord::Migration[5.2]
  def change
    create_table :siac_clientes do |t|
      t.integer :user_id,     null: false
      t.integer :regional_id, null: false
      t.integer :parent_id
      t.boolean :activo, default: true, null: false

      t.timestamps
    end

    add_index :siac_clientes, :user_id
    add_index :siac_clientes, :regional_id
    add_index :siac_clientes, :parent_id

    # Garantiza un solo cliente padre por regional (parent_id = NULL)
    add_index :siac_clientes,
              [:regional_id, :parent_id],
              unique: true,
              name: 'idx_siac_clientes_regional_parent'
  end
end
