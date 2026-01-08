class Convocatoria < ActiveRecord::Base
  self.table_name = 'convocatorias'
  
  has_many :bookmarks, dependent: :destroy
  has_many :users, through: :bookmarks

 # Relación muchos a muchos con Sede
 has_and_belongs_to_many :sedes, 
 class_name: 'Sede', 
 join_table: 'convocatorias_sedes', 
 foreign_key: 'convocatoria_id', 
 association_foreign_key: 'sede_id'

# Relación muchos a muchos con Componente
has_and_belongs_to_many :componentes,
  class_name: 'Componente', 
  join_table: 'convocatorias_componentes',
  foreign_key: 'convocatoria_id',
  association_foreign_key: 'componente_id'

# Relación muchos a muchos con Especialidad
has_and_belongs_to_many :especialidades, 
 class_name: 'Especialidad', 
 join_table: 'convocatorias_especialidades', 
 foreign_key: 'convocatoria_id', 
 association_foreign_key: 'especialidad_id'
end
