class CreateRespuestasFormulario < ActiveRecord::Migration[5.2]
  def change
    create_table :respuestas_formulario do |t|
      t.references :campo, foreign_key: true, null: true
      t.references :subcampo, foreign_key: true, null: true
      t.references :usuario # opcional

      t.text :respuesta_texto  # para texto libre

      t.timestamps
    end
  end
end
