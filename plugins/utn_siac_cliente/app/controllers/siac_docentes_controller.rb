# plugins/utn_siac_cliente/app/controllers/siac_docentes_controller.rb
class SiacDocentesController < ApplicationController
  before_action :require_login
  before_action :require_siac_cliente_permission

  def buscar_por_cuit
    cuit = params[:cuit]

    docente = Siac::DocentesRepository.buscar_por_cuit(cuit)

    if docente
      apellido, nombre = docente['nombre_completo']
        .split(',')
        .map(&:strip)

      render json: {
        found: true,
        cuil: docente['cuil'],
        nombre: nombre,
        apellido: apellido,
        legajo: docente['legajo']
      }
    else
      render json: { found: false }
    end
  end

  private

  def require_siac_cliente_permission
    render_403 unless User.current&.siac_cliente?
  end
end
