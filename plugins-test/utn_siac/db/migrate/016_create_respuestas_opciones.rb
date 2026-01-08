class CreateRespuestasOpciones < ActiveRecord::Migration[5.2]
  def change
    create_table :respuestas_opciones do |t|
      t.references :respuestas_formulario,
                   foreign_key: { to_table: :respuestas_formulario },
                   null: false
      t.references :opciones_campos,
                   foreign_key: true,
                   null: false

      t.timestamps
    end
  end
end
