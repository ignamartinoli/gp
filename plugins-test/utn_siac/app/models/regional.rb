class Regional < ActiveRecord::Base
  self.table_name = 'regionales'
  has_many :sedes
  has_many :especialidadXSede
end
