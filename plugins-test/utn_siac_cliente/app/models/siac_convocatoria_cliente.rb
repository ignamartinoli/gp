class SiacConvocatoriaCliente < ActiveRecord::Base
  self.table_name = 'siac_convocatoria_clientes'

  belongs_to :convocatoria
  belongs_to :siac_cliente
end
