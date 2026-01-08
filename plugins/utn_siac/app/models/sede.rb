class Sede < ActiveRecord::Base
 self.table_name = 'sedes'

 # sedes.regional references regionales.codigo (not id)
 belongs_to :regional,
            class_name: 'Regional',
            foreign_key: 'regional',
            primary_key: 'codigo'

 has_and_belongs_to_many :convocatorias,
                         class_name: 'Convocatoria',
                         join_table: 'convocatorias_sedes',
                         foreign_key: 'sede_id',
                         association_foreign_key: 'convocatoria_id'

 has_and_belongs_to_many :especialidades,
                         class_name: 'Especialidad',
                         join_table: :especialidades_sedes,
                         foreign_key: :sede_id,
                         association_foreign_key: :especialidad_id # <-- use *_id

 def self.for_especialidad(especialidad_id)
  return none if especialidad_id.blank?

  result = ActiveRecord::Base.connection.exec_query(
   'SELECT * FROM SIAC_BUSCAR_UNIDADES_ACADEMICAS_X_CARRERA($1)',
   'SQL',
   [[nil, especialidad_id.to_i]]
  )

  # result.columns => ["id_facultad", "nombre", "extensiones"]
  idx_id_facultad = result.columns.index('id_facultad')
  facultad_ids    = result.rows.map { |row| row[idx_id_facultad].to_i }.uniq

  return none if facultad_ids.empty?

  Sede
   .left_joins(:regional)
   .includes(:regional)
   .where(regionales: { id: facultad_ids })
   .distinct
   .order('sedes.nombre ASC')
 end
end
