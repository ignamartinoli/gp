class CreateRespuestasFormulario < ActiveRecord::Migration[5.2]
  def change
    create_table :respuestas_formulario do |t|
      t.references :campo, foreign_key: true, null: false
      t.references :usuario # Si necesitas saber quién responde
      t.text :respuesta_texto  # Para campos tipo text area y descripción de "2 opciones con descripción"
      t.timestamps
    end
  end
end
