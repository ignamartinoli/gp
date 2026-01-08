class CreateOpcionesCampos < ActiveRecord::Migration[5.2]
  def change
    create_table :opciones_campos do |t|
      t.references :campo, foreign_key: true, null: false
      t.string :opcion, null: false  # La opción visible para el usuario
      t.integer :valor, null: false  # Un identificador interno para la opción

      t.timestamps
    end
  end
end
