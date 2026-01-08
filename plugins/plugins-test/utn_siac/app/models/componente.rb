class Componente < ActiveRecord::Base
  self.table_name = 'componentes'  # 👈 Se asegura de que use la tabla correcta

  belongs_to :dimension,  # Relación de un componente a una dimensión
    class_name: 'Dimension',  # Asegura que use el modelo correcto
    foreign_key: 'dimension_id'  # La columna que hace referencia a Dimension
  
  has_and_belongs_to_many :convocatorias,
    class_name: 'Convocatoria',
    join_table: 'convocatoria_componentes',
    foreign_key: 'componente_id',
    association_foreign_key: 'convocatorias_id'

  has_many :campos, inverse_of: :componente, dependent: :destroy
  accepts_nested_attributes_for :campos, allow_destroy: true

end
