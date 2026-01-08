class Especialidad < ActiveRecord::Base
	self.table_name = 'especialidades'

	has_and_belongs_to_many :convocatorias,
																									class_name: 'Convocatoria',
																									join_table: 'convocatoria_especialidades',
																									foreign_key: 'especialidad_id', # <-- use *_id
																									association_foreign_key: 'convocatoria_id'

	has_and_belongs_to_many :sedes,
																									class_name: 'Sede',
																									join_table: :especialidades_sedes,
																									foreign_key: :especialidad_id, # <-- use *_id
																									association_foreign_key: :sede_id
end
