class CreateRespuestasOpciones < ActiveRecord::Migration[5.2]
  def change
    create_table :respuestas_opciones do |t|
      # Cambia el nombre de la tabla en la clave foránea
      t.references :respuestas_formulario, foreign_key: { to_table: :respuestas_formulario }, null: false
      t.references :opciones_campos, foreign_key: true, null: false  # La opción seleccionada
      t.timestamps
    end
  end
end
