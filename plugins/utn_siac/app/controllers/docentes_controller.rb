class DocentesController < ApplicationController
  before_action :require_login
  include Siac::ControllerGuard

  # Mantener el guard original (define el callback)
  # before_action :deny_siac_cliente!

  # Permitimos que el cliente use estos endpoints del componente
  skip_before_action :deny_siac_cliente!, raise: false, only: %i[
    buscar datos catalogos guardar por_materia por_cuit
  ]

  # Autorización específica para SIAC Docentes (admin o cliente)
  before_action :authorize_siac_docentes!, only: %i[
    buscar datos catalogos guardar por_materia por_cuit
  ]

  def authorize_siac_docentes!
    # admin o usuario “cliente” (ajustá el predicate al que uses)
    allowed = User.current&.admin? || User.current&.siac_cliente?
    return if allowed

    render json: { ok: false, error: 'No autorizado' }, status: :forbidden
  end

  # =========================
  # BUSCAR DOCENTE (CUIT / APELLIDO / LEGAJO)
  # =========================
  def buscar
    docentes = Siac::DocentesRepository.buscar_docentes(
      cuil: params[:cuil],
      apellido: params[:apellido],
      legajo: params[:legajo]
    )

    render json: docentes
  end

  def por_materia
    cliente = SiacCliente.find_by(user_id: User.current.id, activo: true)
    return render json: { ok: false, error: 'Cliente no configurado' }, status: 422 unless cliente

    codigo = params[:codigo_materia].to_s.strip
    return render json: { ok: false, error: 'codigo_materia requerido' }, status: 400 if codigo.blank?

    docentes = Siac::DocentesRepository.docentes_por_materia(
      codigo_materia: codigo,
      id_facultad: cliente.regional_id
    )

    render json: { ok: true, docentes: docentes }
  end

  def por_cuit
    cliente = SiacCliente.find_by(user_id: User.current.id, activo: true)
    return render json: { ok: false, error: 'Cliente no configurado' }, status: 422 unless cliente

    cuil = params[:cuil].to_s.strip
    return render json: { ok: false, error: 'CUIT/CUIL inválido' }, status: 400 unless cuil =~ /^\d{11}$/

    codigo = params[:codigo_materia].to_s.strip.presence
    id_facultad = cliente.regional_id

    persona = Siac::DocentesRepository.docente_basico_por_cuit(cuil: cuil)
    return render json: { ok: true, found: false } unless persona

    ya_en_materia = Siac::DocentesRepository.cargo_activo_existente?(
      cuil: cuil,
      id_facultad: id_facultad,
      codigo_materia: codigo
    )

    # TODO: estos dos los implementamos en el repo y los devolvés
    empleo = Siac::DocentesRepository.empleo_por_cuil(cuil: cuil)              # <- sin materia
    investigacion = Siac::DocentesRepository.investigacion_por_cuil(cuil: cuil) # <- sin materia

    render json: {
      ok: true,
      found: true,
      docente: {
        cuil: persona['cuil'],
        nombre: persona['nombre'],
        apellido: persona['apellido'],
        fecha_nacimiento: persona['fecha_nacimiento']
      },
      empleo: empleo,
      investigacion: investigacion,
      ya_en_materia: ya_en_materia
    }
  end

  # =========================
  # DATOS COMPLETOS DOCENTE
  # =========================
  def datos
    cuil = params[:cuil]

    render json: {
      cargos: Siac::DocentesRepository.cargos_docentes(cuil),
      investigaciones: Siac::DocentesRepository.investigaciones_docente(cuil)
    }
  end

  # =========================
  # CATÁLOGOS PARA SELECTS
  # =========================
  def catalogos
    render json: {
      cargos: Siac::DocentesRepository.cargos_docentes_catalogo,
      grupos: Siac::DocentesRepository.grupos_investigacion,
      centros: Siac::DocentesRepository.centros_investigacion
    }
  end

  # =========================
  # GUARDAR DOCENTE + CARGO
  # =========================
  def guardar
    cliente = SiacCliente.find_by!(user_id: User.current.id, activo: true)
    id_facultad = cliente.regional_id

    docente = docente_params.to_h.symbolize_keys

    tipo_especialidad = resolve_tipo_especialidad(docente[:id_especialidad])
    return render json: { ok: false, error: 'Especialidad inválida' }, status: 422 unless tipo_especialidad

    docente[:tipo_especialidad] = tipo_especialidad
    docente[:id_facultad] = id_facultad

    # 1) insertar docente (y chequear p_resultado como ya hiciste)
    rows = Siac::DocentesRepository.insertar_docente_result(**docente)
    p_resultado = rows.first&.[]('p_resultado') || rows.first&.values&.first
    if p_resultado.present? && p_resultado.to_i != 1
      return render json: { ok: false, error: "SIAC_INSERTAR_DOCENTE rechazó (p_resultado=#{p_resultado})" }, status: 422
    end

    # 2) evitar duplicado por materia
    cargo = cargo_params.to_h.symbolize_keys
    #if Siac::DocentesRepository.cargo_activo_existente?(
    #  codigo_materia: cargo[:codigo_materia],
    #  id_facultad: id_facultad,
    #  cuil: cargo[:cuil]
    #)
    #  return render json: { ok: false, error: 'Ese docente ya está cargado en esta materia.' }, status: 422
    #end

    # 3) insertar cargo
    Siac::DocentesRepository.insertar_cargo_docente(
      codigo_materia: cargo[:codigo_materia],
      id_facultad: id_facultad,
      cuil: cargo[:cuil],
      fecha_asignacion: cargo[:fecha_asignacion],
      horas: cargo[:horas],
      id_cargo: cargo[:id_cargo],
      fecha_baja: cargo[:fecha_baja]
    )

    render json: { ok: true }
  end


  # =========================
  # CATÁLOGO CARGOS DOCENTES
  # =========================
  def self.cargos_docentes_catalogo
      SiacRepository.query(
      'SELECT * FROM SIAC_OBTENER_CARGOS_DOCENTES'
      )
  end

  private

  def docente_params
    params.require(:docente).permit(
      :cuil,
      :nombre,
      :apellido,
      :legajo,
      :fecha_nacimiento,
      :titulacion,          # ✅ agregalo
      :tipo_especialidad,
      :id_facultad,
      :legajo,
      :id_especialidad
    ).to_h.symbolize_keys
  end

  def cargo_params
    params.require(:cargo).permit(
      :codigo_materia,
      :cuil,
      :fecha_asignacion,
      :horas,
      :id_cargo,
      :id_comision, 
      :fecha_baja
    ).to_h.symbolize_keys
  end

  def resolve_tipo_especialidad(id_especialidad)
    row = SiacRecord.connection.exec_query(<<~SQL, "SIAC", [[nil, id_especialidad]]).first
      SELECT tipo_especialidad
      FROM "SPYP_Especialidades"
      WHERE id_especialidad = $1
    SQL

    row && row["tipo_especialidad"]&.to_i
  end
end
