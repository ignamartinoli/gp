class Siac::DocentesController < ApplicationController
  before_action :require_login
  include Siac::ControllerGuard
  before_action :deny_siac_cliente!
  before_action :authorize_siac

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
    Siac::DocentesRepository.insertar_docente(**docente_params)
    Siac::DocentesRepository.insertar_cargo_docente(**cargo_params)

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

  def authorize_siac
    render json: { error: 'No autorizado' }, status: :forbidden unless User.current.admin?
  end

  def docente_params
    params.require(:docente).permit(
      :cuil,
      :nombre,
      :apellido,
      :fecha_nacimiento,
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
      :fecha_baja
    ).to_h.symbolize_keys
  end
end
