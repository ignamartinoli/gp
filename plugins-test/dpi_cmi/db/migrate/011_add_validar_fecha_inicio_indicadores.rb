class AddValidarFechaInicioIndicadores < ActiveRecord::Migration
  def change
  	add_column :projects, :cmi_validar_fecha_inicio_indicadores, :boolean, default: false
  end
end
