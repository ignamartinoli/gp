class ChangeTipoIndicadorTexto < ActiveRecord::Migration
	def up
		act=0
		Issue.where("tipo_indicador='CheckBox'").each do |i|
			i.tipo_indicador="de Resultado"
	        i.save!
	        act+=1
		end
		puts "Se actualizaron #{act} issues de tipo 'CheckBox' a 'de Resultado'."
	end
	def down
		puts "Nada para hacer."
	end
end