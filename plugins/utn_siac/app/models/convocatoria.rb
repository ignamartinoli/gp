class Convocatoria < ActiveRecord::Base
 self.table_name = 'convocatorias'

 has_many :bookmarks,
         foreign_key: :convocatorias_id,
         dependent: :destroy

 has_many :users, through: :bookmarks

 has_and_belongs_to_many :sedes,
                         class_name: 'Sede',
                         join_table: 'convocatorias_sedes',
                         foreign_key: 'convocatoria_id',
                         association_foreign_key: 'sede_id'

 has_and_belongs_to_many :componentes,
                         class_name: 'Componente',
                         join_table: 'convocatorias_componentes',
                         foreign_key: 'convocatoria_id',
                         association_foreign_key: 'componente_id'

 has_and_belongs_to_many :especialidades,
                         class_name: 'Especialidad',
                         join_table: 'convocatorias_especialidades',
                         foreign_key: 'convocatoria_id',
                         association_foreign_key: 'especialidad_id'

has_many :siac_convocatoria_clientes
has_many :siac_clientes, through: :siac_convocatoria_clientes


 # ---- AÑADIR ESTO ----
 scope :search, lambda { |q|
  next all if q.blank?

  pattern = "%#{q.strip.downcase}%"
  where('LOWER(resolucion) LIKE ? OR LOWER(nombre) LIKE ?', pattern, pattern)
 }
end
