class EspecialidadSede < ActiveRecord::Base
  self.table_name = 'especialidades_sedes' # Especifica el nombre correcto de la tabla

  belongs_to :especialidad
  belongs_to :sede

  validates :activo, presence: true, numericality: { only_integer: true }
end
