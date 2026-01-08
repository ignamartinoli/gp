module Siac
  class MateriasPorEspecialidad
    def self.call(especialidad_id)
      sql = <<~SQL
        WITH plan_actual AS (
          SELECT id_plan
          FROM siac_buscar_planes_x_especialidad($1)
          ORDER BY id_plan DESC
          LIMIT 1
        )
        SELECT
          m.codigo_materia,
          m.nombre,
          m.anio,
          m.nivel,
          m.horas
        FROM plan_actual p
        CROSS JOIN LATERAL
          siac_buscar_materias_x_plan($1, p.id_plan) m
        ORDER BY
          m.anio,
          m.nivel;
      SQL

      SiacRecord.connection.exec_query(
        sql,
        "SiacMateriasPlanActual",
        [[nil, especialidad_id]]
      ).to_a
    end
  end
end
