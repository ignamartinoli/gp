class TipoCampo < ActiveRecord::Base
  self.table_name = 'tipos_campo'
  has_many :campos
end
