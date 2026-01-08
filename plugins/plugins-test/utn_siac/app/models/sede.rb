class Sede < ActiveRecord::Base
  self.table_name = 'sedes'
  belongs_to :regional
  
  has_and_belongs_to_many :convocatorias, 
    class_name: 'Convocatoria',  # Asegura que use el modelo correcto
    join_table: 'convocatorias_sedes', 
    foreign_key: 'sede_id', 
    association_foreign_key: 'convocatoria_id'

  has_and_belongs_to_many :especialidades, 
    class_name: 'Especialidad',  # Asegura que use el modelo correcto
    join_table: :especialidades_sedes, 
    foreign_key: :sede_id, 
    association_foreign_key: :especialidad_codigo
end
