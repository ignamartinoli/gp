class AddValorAutomatico < ActiveRecord::Migration[4.2]
  def change
  	add_column :issues, :valor_automatico, :boolean, default: false
  end
end
