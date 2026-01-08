class SiacController < ApplicationController
  before_action :require_login
  include Siac::ControllerGuard

  before_action :deny_siac_cliente!
  before_action :authorize_siac

  def personas_convocatoria
    key = "siac_convocatoria_#{params[:regional]}_#{params[:carrera]}_#{params[:periodo]}"

    data = Rails.cache.fetch(key, expires_in: 15.minutes) do
        SiacRepository.function(
        'SIAC_EGRESADOS_X_CARRERA_X_REGIONAL',
        params[:regional] || 93,
        params[:carrera]  || 4,
        params[:periodo]  || '4-6'
        )
    end

    render json: data
  end

  def buscar_docente
    data = Siac::DocentesRepository.buscar(
      cuil: params[:cuil]
    )

    render json: data
  end

  def crear_docente
    Siac::DocentesRepository.insertar(
      cuil: params[:cuil],
      nombre: params[:nombre],
      apellido: params[:apellido],
      fecha_nacimiento: params[:fecha_nacimiento],
      tipo_especialidad: params[:tipo_especialidad],
      id_facultad: params[:id_facultad]
    )

    render json: { ok: true }
  end

  def cargos_docentes
    data = Siac::DocentesRepository.cargos_docentes_catalogo

    render json: data.map { |c|
      {
        id: c['id_cargo'],
        label: c['nombre']
      }
    }
  end


  private

  def authorize_siac
    unless User.current.admin?
      render json: { error: 'No autorizado' }, status: :forbidden
    end
  end
end
