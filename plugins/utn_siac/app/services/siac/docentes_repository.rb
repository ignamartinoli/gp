module Siac
  class DocentesRepository

    # =========================
    # BUSCAR DOCENTES
    # =========================
    def self.buscar_docentes(cuil: nil, apellido: nil, legajo: nil)
      SiacRepository.function(
        'SIAC_BUSCAR_DOCENTES_X_PARAMETROS',
        cuil,
        apellido,
        legajo
      )
    end

    # =========================
    # INSERTAR DOCENTE
    # =========================
    def self.insertar_docente(
      cuil:,
      nombre:,
      apellido:,
      fecha_nacimiento: nil,
      fecha_alta: Date.today,
      tipo_especialidad:,
      id_facultad:,
      id_cv: nil,
      legajo: nil,
      id_especialidad: nil
      )
      SiacRepository.procedure(
          'SIAC_INSERTAR_DOCENTE',
          nil,                # p_resultado OUT
          cuil,
          nombre,
          apellido,
          fecha_nacimiento,
          fecha_alta,
          tipo_especialidad,
          id_facultad,
          id_cv,
          legajo,
          id_especialidad
      )
    end

    def self.buscar_por_cuit(cuil)
      return nil if cuil.blank?

      resultado = buscar_docentes(cuil: cuil)

      return nil if resultado.blank?

      resultado.first
    end

    def self.cargos_por_ambito
      {
          docente: SiacRepository.query('SELECT * FROM SIAC_OBTENER_CARGOS_DOCENTES'),
          investigacion: SiacRepository.query('SELECT * FROM SIAC_OBTENER_CARGOS_INVESTIGACION'),
          administrativo: SiacRepository.query('SELECT * FROM SIAC_OBTENER_CARGOS_ADMINISTRATIVOS'),
          otros: SiacRepository.query('SELECT * FROM SIAC_OBTENER_CARGOS_OTROS')
      }
    end

    # -----------------------------------------
    # INSERTAR CARGO DOCENTE (typed)
    # -----------------------------------------
    def self.insertar_cargo_docente(
        codigo_materia:,
        id_facultad:,
        cuil:,
        fecha_asignacion:,
        horas:,
        id_cargo:,
        fecha_baja: nil
      )
        fa = fecha_asignacion.presence
        fa = Date.parse(fa.to_s) unless fa.is_a?(Date)

        fb = fecha_baja.presence
        fb = Date.parse(fb.to_s) unless fb.nil? || fb.is_a?(Date)

        Siac::SiacRepository.procedure_typed('SIAC_INSERTAR_CARGOS_DOCENTES', [
          { value: nil,                       cast: 'integer' },          # p_resultado INOUT
          { value: codigo_materia.to_s,       cast: 'varchar' },          # c_codigo_materia
          { value: id_facultad.to_i,          cast: 'integer' },          # c_id_facultad
          { value: cuil.to_s.to_i,            cast: 'bigint' },           # c_cuil_docente
          { value: fa,                        cast: 'date' },             # c_fecha_asignacion
          { value: horas.to_f,                cast: 'double precision' }, # c_horas_asignadas
          { value: id_cargo.to_i,             cast: 'integer' },          # c_id_cargo
          { value: fb,                        cast: 'date' }              # c_fecha_baja
        ])
    end

    # -----------------------------------------
    # INSERTAR DOCENTE (typed) -> devuelve rows
    # -----------------------------------------
    def self.insertar_docente_result(**h)
      fn = h[:fecha_nacimiento].presence
      fn = Date.parse(fn.to_s) unless fn.nil? || fn.is_a?(Date)

      fa = (h[:fecha_alta].presence || Date.today)
      fa = Date.parse(fa.to_s) unless fa.is_a?(Date)

      Siac::SiacRepository.procedure_typed('SIAC_INSERTAR_DOCENTE', [
        { value: nil,                                  cast: 'integer' }, # p_resultado INOUT
        { value: h[:cuil].to_s.to_i,                   cast: 'bigint'  },
        { value: h[:nombre].to_s,                      cast: 'varchar' },
        { value: h[:apellido].to_s,                    cast: 'varchar' },
        { value: fn,                                   cast: 'date'    },
        { value: fa,                                   cast: 'date'    },
        { value: h[:tipo_especialidad].to_i,           cast: 'integer' },
        { value: h[:id_facultad].to_i,                 cast: 'integer' },
        { value: h[:id_cv].presence&.to_i,             cast: 'integer' },
        { value: h[:legajo].presence&.to_i,            cast: 'integer' },
        { value: h[:id_especialidad].presence&.to_i,   cast: 'integer' }
      ])
    end

    def self.cargo_activo_existente?(cuil:, codigo_materia:, id_facultad:)
      sql = ActiveRecord::Base.send(
        :sanitize_sql_array,
        [<<~SQL, cuil.to_i, codigo_materia.to_s, id_facultad.to_i]
          SELECT 1
          FROM public."SIAC_CargosXDocentes"
          WHERE cuil_docente = ?
            AND codigo_materia = ?
            AND id_facultad = ?
            AND (fecha_baja IS NULL OR fecha_baja > CURRENT_DATE)
          LIMIT 1
        SQL
      )

      Siac::SiacRepository.connection.select_value(sql).present?
    end

    # Helper opcional: extraer p_resultado de insertar_docente_result
    def self.p_resultado(rows)
      return nil if rows.blank?
      rows.first['p_resultado'] || rows.first.values.first
    end

    def self.legajo_existe?(legajo)
      return false if legajo.blank?
      sql = 'SELECT 1 FROM "SIAC_Docentes" WHERE legajo_docente = ? LIMIT 1'
      SiacRepository.select_value(sql, legajo).present?
    end

    def self.docente_existe?(cuil:)
      sql = ActiveRecord::Base.send(
        :sanitize_sql_array,
        [<<~SQL, cuil.to_i]
          SELECT 1
          FROM public."SIAC_Docentes"
          WHERE cuil = ?
          LIMIT 1
        SQL
      )

      Siac::SiacRepository.connection.select_value(sql).present?
    end

    # =========================
    # CATÁLOGOS – DOCENTES
    # =========================
    def self.cargos_docentes_catalogo
      Siac::SiacRepository.query(
        'SELECT * FROM SIAC_OBTENER_CARGOS_DOCENTES'
      )
    end

    # =========================
    # CATÁLOGOS – INVESTIGACIÓN
    # =========================
    def self.cargos_investigacion_catalogo
      Siac::SiacRepository.query(
        'SELECT * FROM SIAC_OBTENER_CARGOS_INVESTIGACION'
      )
    end

    # =========================
    # CATÁLOGOS – ADMINISTRATIVOS
    # =========================
    def self.cargos_administrativos_catalogo
      Siac::SiacRepository.query(
        'SELECT * FROM SIAC_OBTENER_CARGOS_ADMINISTRATIVOS'
      )
    end

    # =========================
    # CATÁLOGOS – OTROS
    # =========================
    def self.cargos_otros_catalogo
      Siac::SiacRepository.query(
        'SELECT * FROM SIAC_OBTENER_CARGOS_OTROS'
      )
    end

    def self.actualizar_cv_docente(cuil:, id_cv_adjunto:)
      sql = ActiveRecord::Base.send(
        :sanitize_sql_array,
        [<<~SQL, id_cv_adjunto.to_i, cuil.to_i]
          UPDATE public."SIAC_Personas"
          SET id_cv_adjunto = ?
          WHERE cuil = ?
        SQL
      )

      Siac::SiacRepository.connection.execute(sql)
    end

    def self.docentes_por_materia(codigo_materia:, id_facultad:)
      sql = <<~SQL
        SELECT
          p.cuil,
          p.nombre,
          p.apellido,
          cd.id_cargo,
          cd.horas_asignadas,
          cd.fecha_asignacion
        FROM public."SIAC_CargosXDocentes" cd
        JOIN public."SIAC_Personas" p ON p.cuil = cd.cuil_docente
        WHERE cd.codigo_materia = ?
          AND cd.id_facultad = ?
          AND (cd.fecha_baja IS NULL OR cd.fecha_baja > CURRENT_DATE)
        ORDER BY cd.fecha_asignacion DESC
      SQL

      Siac::SiacRepository.connection.exec_query(
        ActiveRecord::Base.send(:sanitize_sql_array, [sql, codigo_materia, id_facultad])
      ).to_a
    end

    def self.tipo_especialidad_por_id(id_especialidad)
      return nil if id_especialidad.blank?

      sql = ActiveRecord::Base.send(
        :sanitize_sql_array,
        [<<~SQL, id_especialidad.to_i]
          SELECT tipo_especialidad
          FROM public."SPYP_Especialidades"
          WHERE id_especialidad = ?
          LIMIT 1
        SQL
      )

      Siac::SiacRepository.connection.exec_query(sql).to_a.first&.[]("tipo_especialidad")
    end

    def self.tipos_especialidad_catalogo
      rows = Siac::SiacRepository.connection.exec_query(<<~SQL).to_a
        SELECT id_tipo_especialidad, nombre, nivel
        FROM public.siac_obtener_tipos_especialidad
        ORDER BY nombre
      SQL

      rows.map do |r|
        id = r["id_tipo_especialidad"].to_i
        {
          "id" => id,
          "nombre" => nombre_tipo_especialidad(id)
        }
      end.uniq { |r| r["nombre"] }
    end
    
    def self.nombre_tipo_especialidad(id)
      case id.to_i
      when 1, 2, 12
        "Técnico/a"
      when 3
        "Ingeniero/a"
      when 4, 7
        "Especialista"
      when 5
        "Magíster"
      when 6
        "Doctor/a"
      when 8
        "Profesor/a"
      when 11
        "Licenciado/a"
      else
        "Otro"
      end
    end

    def self.docente_basico_por_cuit(cuil:)
      sql = ActiveRecord::Base.send(
        :sanitize_sql_array,
        [<<~SQL, cuil.to_i]
          SELECT
            p.cuil,
            p.nombre,
            p.apellido,
            p.fecha_nacimiento,
            p.id_cv_adjunto,
            d.legajo_docente AS legajo,
            d.id_especialidad,
            d.tipo_especialidad_recibido
          FROM public."SIAC_Personas" p
          LEFT JOIN public."SIAC_Docentes" d ON d.cuil = p.cuil
          WHERE p.cuil = ?
          LIMIT 1
        SQL
      )

      Siac::SiacRepository.connection.exec_query(sql).to_a.first
    end

    def self.cv_por_attachment_id(id_cv)
      Rails.logger.warn("CV DEBUG buscando attachment id=#{id_cv.inspect}")
      return nil if id_cv.blank?

      attachment = Attachment.find_by(id: id_cv)
      Rails.logger.warn("CV DEBUG attachment encontrado=#{attachment.inspect}")

      return nil unless attachment

      {
        id: attachment.id,
        filename: attachment.filename,
        filesize: attachment.filesize,
        content_type: attachment.content_type
      }
    end

  end
end
