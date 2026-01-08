class Dimension < ActiveRecord::Base
  self.table_name = 'dimensiones'  # 👈 Se asegura de que use la tabla correcta

  has_many :componentes,  # Relación uno a muchos con Componente
  class_name: 'Componente',  # Asegura que use el modelo correcto
  foreign_key: 'dimension_id'  # La columna que hace referencia a Dimension

end
