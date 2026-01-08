class ComponenteController < ApplicationController
  include Siac::ControllerGuard
  

  before_action :deny_siac_cliente!

  def index
    @componentes = Componente.page(params[:page]).per(10).where(activo: 1).order(dimension_id: :asc)
  end

  def new
    @componente = Componente.new
    campo = @componente.campos.build
    campo.subcampos.build if campo.subcampos.empty? # 🧩 importante
    @dimensiones = Dimension.all
    @tipos_campo = TipoCampo.where(activo: 1)
  end
  
  def create
    Rails.logger.info "🧠 PARAMS RECIBIDOS:"
    Rails.logger.info params[:componente].to_unsafe_h.inspect

    @componente = Componente.new(componente_params)

    if @componente.save
      Rails.logger.info "✅ Componente guardada correctamente"
      redirect_to componentes_path
    else
      Rails.logger.error "❌ Error al guardar: #{@componente.errors.full_messages}"

      @dimensiones = Dimension.all
      @tipos_campo = TipoCampo.where(activo: 1)

      @componente.campos.each_with_index do |campo, i|
        Rails.logger.error "Campo #{i}: #{campo.errors.full_messages}" if campo.errors.any?
        campo.subcampos.each_with_index do |sub, j|
          Rails.logger.error "  Subcampo #{j}: #{sub.errors.full_messages}" if sub.errors.any?
        end
      end
      render :new
    end
  end

  
  def preview
    @componente = Componente
      .includes(campos: [:subcampos, :opciones_campos, :tipo_campo])
      .find(params[:id])

    @campos_convocatoria  = @componente.campos.where(activo: 1, autoevaluacion: 0)
    @campos_autoevaluacion = @componente.campos.where(activo: 1, autoevaluacion: 1)

    # 🔽 NUEVO
    @grupos_investigacion  = SiacRepository.query('SELECT id_grupo, denominacion FROM siac_obtener_grupos_investigacion')
    @centros_investigacion = SiacRepository.query('SELECT id_grupo, denominacion FROM siac_obtener_centros_investigacion')

    render :preview
  end



  def show
    @componente = Componente.find(params[:id])
  end

 def edit
    @componente = Componente
        .includes(campos: [:opciones_campos, subcampos: :opciones_campos])
        .find(params[:id])

    @dimensiones = Dimension.all
    @tipos_campo = TipoCampo.where(activo: 1)

   @componente.campos.each do |campo|
      campo.opciones_campos.build if campo.opciones_campos.empty?
      campo.subcampos.build if campo.subcampos.empty?
      campo.subcampos.each do |subcampo|
        subcampo.opciones_campos.build if subcampo.opciones_campos.empty?
      end
    end


    @campos_convocatoria = @componente.campos.where(activo: 1, autoevaluacion: 0)
    @campos_autoevaluacion = @componente.campos.where(activo: 1, autoevaluacion: 1)
  end


  

  def update
    @componente = Componente.find_by(id: params[:id])
    if @componente.nil?
      logger.debug "Componente con id #{params[:id]} no encontrado"
      redirect_to componentes_path, alert: 'Componente no encontrado.'
      return
    end

    logger.debug "Parámetros recibidos: #{params.inspect}"

    submitted_campos = params[:componente][:campos_attributes] || {}

    submitted_campos.each do |index, field_data|
      if field_data["id"].present?
        campo = @componente.campos.find_by(id: field_data["id"])
        next unless campo

        if field_data["pregunta"].present? && field_data["tipo_campo_id"].present? &&
          ( field_data["tiene_pregunta_orientadora"].to_s == "0" || field_data["descripcion"].present? )
          campo.update(activo: 1)
        else
          campo.update(activo: 0)
        end
      end
    end

    existing_ids = submitted_campos.values.map { |fd| fd["id"] }
    @componente.campos.where.not(id: existing_ids).each do |campo|
      campo.update(activo: 0)
    end

    if @componente.update(componente_params)
      redirect_to componentes_path(@componente), notice: 'Componente actualizado.'
    else
      # ⬇⬇⬇ AGREGAR DESDE ACÁ ⬇⬇⬇

      @dimensiones = Dimension.all
      @tipos_campo = TipoCampo.where(activo: 1)

      @componente.campos.each do |campo|
        campo.opciones_campos.build if campo.opciones_campos.empty?
        campo.subcampos.build if campo.subcampos.empty?
        campo.subcampos.each do |sub|
          sub.opciones_campos.build if sub.opciones_campos.empty?
        end
      end

      @campos_convocatoria = @componente.campos.where(activo: 1, autoevaluacion: 0)
      @campos_autoevaluacion = @componente.campos.where(activo: 1, autoevaluacion: 1)

      # ⬆⬆⬆ HASTA ACÁ ⬆⬆⬆

      render :edit
    end
  end

  

  def destroy
    @componente = Componente.find(params[:id])

    # Marcar el componente como inactivo
    @componente.update(activo: 0)
    @componente.campos.update_all(activo: 0)
    # Redirigir con un mensaje
    redirect_to componentes_path, notice: 'Componente marcado como inactivo.'
  end

  private
    # app/controllers/componente_controller.rb
    def componente_params
      params.require(:componente).permit(
        :nombre, :descripcion, :dimension_id,
        campos_attributes: [
          :id, :autoevaluacion, :pregunta, :obligatorio,
          :tiene_pregunta_orientadora, :descripcion, :tipo_campo_id,
          :permite_adjuntos, :_destroy,

          { opciones_campos_attributes: [:id, :opcion, :valor, :_destroy] },

          { subcampos_attributes: [
              :id, :pregunta, :descripcion, :tipo_campo_id,
              :obligatorio, :tiene_pregunta_orientadora, :permite_adjuntos,
              :posicion, :_destroy,
              { opciones_campos_attributes: [:id, :opcion, :valor, :_destroy] }
            ]
          }
        ]
      )
    end


end
