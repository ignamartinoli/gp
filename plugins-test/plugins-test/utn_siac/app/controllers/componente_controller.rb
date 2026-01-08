class ComponenteController < ApplicationController
  def index
    @componentes = Componente.page(params[:page]).per(10).where(activo: 1).order(dimension_id: :asc)
  end

  def new
    @componente = Componente.new
    @componente.campos.build if @componente.campos.empty?
    @dimensiones = Dimension.all
    @tipos_campo = TipoCampo.where(activo: 1)
  end
  
  def create
    @componente = Componente.new(componente_params)
    logger.debug "Parametros recibidos: #{params.inspect}"
    if @componente.save
      redirect_to componentes_path  
    else
      render :new
    end
  end
  
  

  def show
    @componente = Componente.find(params[:id])
  end

  def edit
    @componente = Componente.find(params[:id])
    @dimensiones = Dimension.all
    @tipos_campo = TipoCampo.where(activo: 1)
    @campos_activos = @componente.campos.where(activo: 1) # Filtra solo los campos activos
  end
  

  def update
    @componente = Componente.find_by(id: params[:id])
    if @componente.nil?
      logger.debug "Componente con id #{params[:id]} no encontrado"
      redirect_to componentes_path, alert: 'Componente no encontrado.'
      return
    end
  
    logger.debug "Parámetros recibidos: #{params.inspect}"
  
    # Obtener los atributos enviados para los campos (nested attributes)
    submitted_campos = params[:componente][:campos_attributes] || {}
  
    # Iterar sobre los campos enviados y actualizar su estado 'activo'
    submitted_campos.each do |index, field_data|
      if field_data["id"].present?
        campo = @componente.campos.find_by(id: field_data["id"])
        next unless campo
  
        # Lógica de activación:
        # - Siempre se requiere que 'pregunta' y 'tipo_campo_id' estén presentes.
        # - Si 'tiene_pregunta_orientadora' es "1", también se requiere que 'descripcion' esté presente.
        if field_data["pregunta"].present? && field_data["tipo_campo_id"].present? &&
           ( field_data["tiene_pregunta_orientadora"].to_s == "0" || field_data["descripcion"].present? )
          campo.update(activo: 1)
        else
          campo.update(activo: 0)
        end
      end
    end
  
    # Opcional: Si hay campos existentes en @componente que NO se enviaron en params,
    # puedes desactivarlos:
    existing_ids = submitted_campos.values.map { |fd| fd["id"] }
    @componente.campos.where.not(id: existing_ids).each do |campo|
      campo.update(activo: 0)
    end
  
    if @componente.update(componente_params)
      redirect_to componentes_path(@componente), notice: 'Componente actualizado.'
    else
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

  def componente_params
    params.require(:componente).permit(
      :nombre,
      :descripcion,
      :dimension_id,
      campos_attributes: [
        :id, 
        :descripcion, 
        :pregunta, 
        :tiene_pregunta_orientadora,
        :permite_adjuntos,
        :tipo_campo_id, 
        :obligatorio,
        :subcampo,
        :subcampo_de,
        :autoevaluacion,
        :activo
      ]
    )
  end
end
