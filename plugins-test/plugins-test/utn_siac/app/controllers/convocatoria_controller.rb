class ConvocatoriaController < ApplicationController

  def new
    @convocatoria = Convocatoria.new
    @titulaciones = [
      ['Licenciaturas', 1],
      ['Ingenierías', 2],
      ['Terciarios', 3],
      ['Tecnicaturas', 4],
      ['Maestrías', 5],
      ['Doctorados', 6]
    ]
    
    @especialidades = Especialidad.where(titulacion: 0)
    @componentes = Componente.where(activo: 1).order(:dimension_id)
    @sedes = []
  
    respond_to do |format|
      format.html # Vista normal
      format.js do
        # Aquí se pasan ambos partials en un solo bloque
        render partial: 'especialidades', locals: { especialidades: @especialidades }
        # Si necesitas el partial de sedes también en la misma respuesta,
        # lo puedes manejar dentro del mismo bloque de format.js
        render partial: 'sedes', locals: { sedes: @sedes }
      end
    end
  end
  

  def cargar_especialidades
    titulacion = params[:titulacion]  # Ahora obtenemos directamente de la URL

    if titulacion.present?
      especialidades = Especialidad.where(titulacion: titulacion, activo: true).order(:nombre)
    else
      render json: { error: 'El parámetro titulacion es requerido.' }, status: :bad_request
      return
    end
    
  
    render partial: 'especialidades', locals: { especialidades: especialidades }
  end  
  
  def cargar_sedes
    especialidades = params[:especialidades]
  
    if especialidades.present?
      # Realizamos la consulta SQL personalizada utilizando ActiveRecord
      @sedes = EspecialidadSede.joins("INNER JOIN especialidades e ON e.codigo = especialidades_sedes.especialidad_id")
                                .joins("INNER JOIN sedes s ON s.id = especialidades_sedes.sede_id")
                                .joins("INNER JOIN regionales r ON s.regional = r.codigo")
                                .select("r.nombre AS 'Facultad', s.nombre AS 'Sede',s.id")  # Seleccionamos solo los campos que necesitamos
                                .where(especialidad: especialidades)
                                .group('r.nombre', 's.nombre','s.id')  # Agrupamos por facultad y sede
                                .order('r.nombre ASC', 's.nombre ASC')  # Ordenamos por facultad y sede
  
      # Esto devolverá los resultados con los datos solicitados
    else
      @sedes = []
    end
  
    render partial: 'sedes', locals: { sedes: @sedes }
  end
   
  
    


  def index
    user_id = User.current.id  # Obtener el ID del usuario actual
  
    if params[:mostrar_cerradas] == 'true'
      @convocatoria = Convocatoria.page(params[:page])
                                  .per(10)
                                  .order(
                                    ActiveRecord::Base.sanitize_sql_array(
                                      ["CASE WHEN id IN (SELECT convocatorias_id FROM bookmarks WHERE user_id = ?) THEN 0 ELSE 1 END", user_id]
                                    )
                                  )
                                  .order(fecha_creacion: :desc)
    else
      @convocatoria = Convocatoria.where.not(estado: 'Cerrada')
                                  .page(params[:page])
                                  .per(10)
                                  .order(
                                    ActiveRecord::Base.sanitize_sql_array(
                                      ["CASE WHEN id IN (SELECT convocatorias_id FROM bookmarks WHERE user_id = ?) THEN 0 ELSE 1 END", user_id]
                                    )
                                  )
                                  .order(fecha_creacion: :desc)
    end
  end
  
  
  
  def create
    # Asegúrate de que los parámetros estén siendo impresos correctamente
    logger.debug "Parametros recibidos: #{params.inspect}"
    
    @convocatoria = Convocatoria.new(convocatoria_params)
    @convocatoria.etapa = 'Nueva'
  
    # Limpiar valores vacíos de sedes_codigos, dimension_codigos y especialidad_codigos
    sedes_codigos = params[:sedes_codigos]&.reject(&:blank?) || []
    componentes_codigos = params[:componentes_codigos]&.reject(&:blank?) || []
    especialidades_codigos = params[:especialidad_codigos]&.reject(&:blank?) || []
    
    logger.debug "Sedes seleccionadas después de limpieza: #{sedes_codigos}"
    logger.debug "Componentes seleccionadas después de limpieza: #{componentes_codigos}"
    logger.debug "Especialidades seleccionadas después de limpieza: #{especialidades_codigos}"
  
    # Asociar las sedes, dimensiones y especialidades a la convocatoria
    @convocatoria.sedes = Sede.where(id: sedes_codigos)
    @convocatoria.componentes = Componente.where(id: componentes_codigos)
    @convocatoria.especialidades = Especialidad.where(id: especialidades_codigos)
    
    logger.debug "Convocatoria con asociaciones antes de guardarse: #{@convocatoria.inspect}"
    
    if @convocatoria.save
      redirect_to convocatorias_path, notice: 'Convocatoria creada con éxito.'
    else
      logger.debug "Errores en la convocatoria: #{@convocatoria.errors.full_messages}"
      flash[:error] = @convocatoria.errors.full_messages.to_sentence
      render :new
    end
  end
  
  


  def destroy
    @convocatoria = Convocatoria.find(params[:id])
    if @convocatoria.destroy
      redirect_to convocatorias_path, notice: 'Convocatoria eliminada correctamente.'
    else
      redirect_to convocatorias_path, alert: 'Error al eliminar la convocatoria.'
    end
  end

  def show
    @convocatoria = Convocatoria.find(params[:id])
  end

  # Nueva acción edit
  def edit
    @convocatoria = Convocatoria.find(params[:id])
    @titulaciones = ['Licenciaturas', 'Ingenierias', 'Terciarios', 'Tecnicaturas', 'Especialidades', 'Doctorados']
  end

  # Acción update
  def update
    @convocatoria = Convocatoria.find(params[:id])
    
    if @convocatoria.update(convocatoria_params)
      redirect_to convocatorias_path, notice: 'Convocatoria actualizada con éxito.'
    else
      render :edit
    end
  end


  def bookmark
    # Encuentra la convocatoria por ID
    @convocatoria = Convocatoria.find(params[:id])
    
    # Verifica si ya existe un registro en 'bookmarks' para el usuario actual y la convocatoria
    existing_bookmark = Bookmark.find_by(convocatorias_id: @convocatoria.id, user_id: User.current.id)

    if existing_bookmark
      # Si ya está marcado, lo eliminamos
      existing_bookmark.destroy
      flash[:notice] = 'Convocatoria desmarcada correctamente.'
    else
      # Si no está marcado, lo creamos
      Bookmark.create(convocatorias_id: @convocatoria.id, user_id: User.current.id)
      flash[:notice] = 'Convocatoria marcada correctamente.'
    end

    # Redirige de vuelta a la lista de convocatorias
    redirect_to convocatorias_path
  end

  def unbookmark
    # Encuentra la convocatoria por ID
    @convocatoria = Convocatoria.find(params[:id])

    # Encuentra el bookmark que el usuario actual tiene para esta convocatoria
    bookmark = Bookmark.find_by(convocatorias_id: @convocatoria.id, user_id: User.current.id)

    if bookmark
      # Si existe, lo eliminamos
      bookmark.destroy
      flash[:notice] = 'Convocatoria desmarcada correctamente.'
    else
      # Si no existe el bookmark, no hacemos nada
      flash[:alert] = 'No se encontró la convocatoria marcada.'
    end

    # Redirige de vuelta a la lista de convocatorias
    redirect_to convocatorias_path
  end

  def buscar
    if params[:query].present?
      @convocatorias = Convocatoria.where("nombre LIKE ?", "%#{params[:query]}%")
    else
      @convocatorias = []
    end
  
    render json: { convocatorias: @convocatorias }
  end
  

  private

  def convocatoria_params
    params.require(:convocatoria).permit(
      :resolucion, 
      :nombre, 
      :fecha_inicio, 
      :fecha_hasta, 
      :titulaciones, 
      :etapa, 
      :estado,
      sedes_codigos: [], 
      componentes_codigos: [], 
      especialidad_codigos: []
    )
  end



end

