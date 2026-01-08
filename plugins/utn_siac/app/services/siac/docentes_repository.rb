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

  end
end
