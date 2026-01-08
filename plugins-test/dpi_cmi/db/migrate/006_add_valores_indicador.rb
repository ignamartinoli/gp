class AddValoresIndicador < ActiveRecord::Migration
	def up
		add_column :issues, :ind_min, :integer
		add_column :issues, :ind_med, :integer
		add_column :issues, :ind_max, :integer
		add_column :issues, :valor, :integer
		add_column :issues, :valor_peso, :integer
		add_column :issues, :tipo_indicador, :string, :default=>"Simetrico"
		add_column :issues, :alcance, :integer, :default=>1

		Issue.all.each do |i|
			 custom_valor = CustomField.where(name: "Valor de Indicador").first
	         min = CustomField.where(name: "Semaforo Min").first
	         med = CustomField.where(name: "Semaforo Med").first
	         max = CustomField.where(name: "Semaforo Max").first
	         peso_cf = CustomField.where(name: "Peso").first

			 value = i.custom_field_values.select{ |v| v.custom_field_id == custom_valor.id }.first
	         ind_min = i.custom_field_values.select{ |v| v.custom_field_id == min.id }.first
	         ind_med = i.custom_field_values.select{ |v| v.custom_field_id == med.id }.first
	         ind_max = i.custom_field_values.select{ |v| v.custom_field_id == max.id }.first
	         peso = i.custom_field_values.select{ |v| v.custom_field_id == peso_cf.id }.first

	         i.ind_min=ind_min.try(:value).to_i
	         i.ind_med=ind_med.try(:value).to_i
	         i.ind_max=ind_max.try(:value).to_i
	         i.valor=value.try(:value).to_i
	         i.valor_peso=peso.try(:value).to_i
	         i.save!
		end
	end
	def down
		remove_column :issues, :ind_min
		remove_column :issues, :ind_med
		remove_column :issues, :ind_max
		remove_column :issues, :valor
		remove_column :issues, :valor_peso
		remove_column :issues, :tipo_indicador
		remove_column :issues, :alcance
	end
end