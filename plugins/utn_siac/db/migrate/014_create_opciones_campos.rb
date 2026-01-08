class CreateOpcionesCampos < ActiveRecord::Migration[5.2]
  def up
    create_table :opciones_campos do |t|
      t.references :campo, foreign_key: true
      t.references :subcampo, foreign_key: true
      t.string :opcion, null: false
      t.string :valor, null: false
      t.timestamps
    end
  end

  def down
    # Verificar existencia de la tabla antes de intentar revertir
    if table_exists?(:opciones_campos)
      if index_exists?(:opciones_campos, :subcampo_id)
        remove_index :opciones_campos, column: :subcampo_id
      end

      if index_exists?(:opciones_campos, :campo_id)
        remove_index :opciones_campos, column: :campo_id
      end

      drop_table :opciones_campos
      puts "🧹 Tabla 'opciones_campos' eliminada correctamente."
    else
      puts "⚠️ Tabla 'opciones_campos' no existe. Se omite rollback."
    end
  end
end
