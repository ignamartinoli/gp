module SiacClienteWeb
  class ConvocatoriasController < ApplicationController
    layout 'base'

    helper ComponenteHelper

    before_action :require_login
    before_action :require_siac_cliente_permission
    before_action :set_convocatoria, only: [:new, :create]

    def index
      @convocatorias = Convocatoria
        .where.not(estado: 'Cerrada')
        .order(:fecha_hasta)
    end

    def new
      @dimensiones = Dimension
        .joins(componentes: :convocatorias)
        .where(convocatorias: { id: @convocatoria.id })
        .distinct
        .order(:id)
    end

    def create
      redirect_to siac_cliente_path,
                  notice: 'Convocatoria enviada correctamente.'
    end

    private

    def set_convocatoria
      @convocatoria = Convocatoria.find(params[:id])
    end

    def require_siac_cliente_permission
      render_403 unless User.current&.siac_cliente?
    end
  end
end
