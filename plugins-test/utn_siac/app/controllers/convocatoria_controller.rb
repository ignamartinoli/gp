require 'prawn'
require 'prawn/table'

class ConvocatoriaController < ApplicationController
  include Siac::ControllerGuard

  before_action :deny_siac_cliente!
  
  helper ComponenteHelper
  include ConvocatoriaHelper
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
  @sedes = Sede
           .left_joins(:regional) # para poder mostrar sede.regional en el parcial
           .includes(:regional)
           .distinct
           .order('sedes.nombre ASC')

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
  titulacion = params[:titulacion] # Ahora obtenemos directamente de la URL

  if titulacion.present?
   especialidades = Especialidad.where(titulacion: titulacion, activo: true).order(:nombre)
  else
   render json: { error: 'El parámetro titulacion es requerido.' }, status: :bad_request
   return
  end

  render partial: 'especialidades', locals: { especialidades: especialidades }
 end

  def cargar_sedes
    especialidades = Array(params[:especialidades]).reject(&:blank?)

    sedes = []

    if especialidades.present?
      conn = SiacPgBase.connection

      especialidades.each do |especialidad_id|
        result = conn.exec_query(
          'SELECT * FROM SIAC_BUSCAR_UNIDADES_ACADEMICAS_X_CARRERA($1)',
          'SQL',
          [[nil, especialidad_id.to_i]]
        )

        result.rows.each_with_index do |row, i|
          sedes << {
            id_facultad: row[result.columns.index('id_facultad')],
            nombre: row[result.columns.index('nombre')],
            extensiones: row[result.columns.index('extensiones')]
          }
        end
      end
    end

    sedes.uniq! { |s| s[:id_facultad] }

    render partial: 'sedes', locals: { sedes: sedes }
  end


 def index
  today = Date.today
  # 1) Actualizar convocatorias vencidas
  Convocatoria.where("fecha_hasta < ? AND estado != 'Cerrada'", today)
        .update_all(estado: "Cerrada")

  user_id = User.current.id

  # 2) Armar la base filtrada
  if params[:mostrar_cerradas] == "true"
    scope = Convocatoria.where(estado: "Cerrada")
  else
    scope = Convocatoria.where.not(estado: "Cerrada")
  end


	# 3) Aplicar búsqueda, paginación y orden
  @convocatoria = scope
                  .search(params[:q]) # <-- filtro por Resolución o Nombre
                  .page(params[:page])
                  .per(10)
                  .order(
                   ActiveRecord::Base.sanitize_sql_array(
                    [
                     'CASE WHEN id IN (SELECT convocatorias_id FROM bookmarks WHERE user_id = ?) THEN 0 ELSE 1 END', user_id
                    ]
                   )
                  )
                  .order(fecha_creacion: :desc)
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

  sedes_ids        = params[:sedes_codigos]&.reject(&:blank?) || []          # consider renaming to sedes_ids if truly IDs
  componentes_ids  = params[:componentes_codigos]&.reject(&:blank?) || []
  especialidad_ids = params[:especialidad_ids]&.reject(&:blank?) || []       # <-- now IDs

  # Asociar las sedes, dimensiones y especialidades a la convocatoria
  @convocatoria.sedes          = Sede.where(id: sedes_ids)
  @convocatoria.componentes    = Componente.where(id: componentes_ids)
  @convocatoria.especialidades = Especialidad.where(id: especialidad_ids)

  logger.debug "Convocatoria con asociaciones antes de guardarse: #{@convocatoria.inspect}"

  if @convocatoria.save
    Siac::CrearClientesPorConvocatoria.new(@convocatoria).call

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

 def preview
  @convocatoria = Convocatoria.find(params[:id])

  @dimensiones = Dimension
                 .joins(componentes: :convocatorias)
                 .where(convocatorias: { id: @convocatoria.id })
                 .distinct
                 .order(:id)
 end

def show
  @convocatoria = Convocatoria.find(params[:id])

  @sedes = @convocatoria
           .sedes
           .includes(:regional)
           .order('regionales.nombre ASC, sedes.nombre ASC')
           .page(params[:page])
           .per(10)


  @dimensiones = Dimension
    .joins(componentes: :convocatorias)
    .where(convocatorias: { id: @convocatoria.id })
    .distinct

  @clientes_por_regional = {}

  siac_clientes = SiacCliente
    .joins(:siac_convocatoria_clientes)
    .where(
      siac_convocatoria_clientes: { convocatoria_id: @convocatoria.id },
      parent_id: nil
    )
    .includes(:user)

  siac_clientes.each do |cliente|
    @clientes_por_regional[cliente.regional_id] = cliente.user
  end
end


 # Nueva acción edit
 def edit
  @convocatoria = Convocatoria.find(params[:id])
  @titulaciones = [
   ['Licenciaturas', 1],
   ['Ingenierías', 2],
   ['Terciarios', 3],
   ['Tecnicaturas', 4],
   ['Maestrías', 5],
   ['Doctorados', 6]
  ]
  # @titulaciones = %w[Licenciaturas Ingenierias Terciarios Tecnicaturas Especialidades Doctorados]
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
  q = params[:query].to_s
  show_closed = params[:mostrar_cerradas] == 'true'

  scope = show_closed ? Convocatoria.all : Convocatoria.where.not(estado: 'Cerrada')

  @convocatorias = if q.present?
                    scope.search(q).select(:id, :resolucion, :nombre).limit(10)
                   else
                    []
                   end

  render json: {
   convocatorias: @convocatorias.map do |c|
    { id: c.id, resolucion: c.resolucion, nombre: c.nombre }
   end
  }
 end

  def pdf_preview
    @convocatoria = Convocatoria.new(convocatoria_params)

    pdf = Prawn::Document.new(
      page_size: "A4",
      margin: [110, 60, 70, 60]
    )

    header(pdf)
    footer(pdf)

    lugar_y_fecha(pdf)
    introduccion(pdf)

    objetivo(pdf)
    alcance(pdf)
    responsables_y_proceso(pdf)

    pdf.start_new_page
    impacto_y_resultados(pdf)
    tabla_resultados(pdf)
    ciclo_de_vida(pdf)

    pdf.start_new_page
    etapas(pdf)

    pdf.start_new_page
    explicacion_uso(pdf)

    send_data pdf.render,
              filename: "Convocatoria_#{@convocatoria.nombre}.pdf",
              type: "application/pdf",
              disposition: "attachment"
  end

  def header(pdf)
    candidates = [
      Rails.root.join("public/plugin_assets/utn_siac/images/utn_logo_capital_humano.png").to_s,
      Rails.root.join("plugins/utn_siac/assets/images/utn_logo_capital_humano.png").to_s
    ]

    logo_path = candidates.find { |p| File.exist?(p) }
    raise "Logo NOT FOUND. Tried: #{candidates.join(' | ')}" unless logo_path

    pdf.repeat(:all) do
      pdf.bounding_box([pdf.bounds.left, pdf.bounds.top + 50], width: pdf.bounds.width) do
        # --- renglón superior (logo + texto) ---
        y_top = pdf.cursor

        # Logo (más grande)
        pdf.image logo_path, fit: [150, 90], at: [0, y_top]

        # Texto a la derecha (en el mismo renglón)
        pdf.text_box(
          "2025 – Año de la Reconstrucción de la Nación Argentina",
          at: [0, y_top],
          width: pdf.bounds.width,
          height: 70,          # mismo alto que el logo para alinear bien
          align: :right,
          valign: :center,
          size: 8,
          style: :bold
        )

        # Bajamos el cursor por debajo del bloque logo/texto
        pdf.move_down 75

        # --- línea separadora (SIEMPRE abajo) ---
        pdf.stroke_color "CCCCCC"
        pdf.stroke_horizontal_rule
        pdf.stroke_color "000000"
      end
    end
  end







  def footer(pdf)
    pdf.number_pages(
      "2025 – Año de la Educación y el Conocimiento para una Sociedad Justa y Democratizadora\nPágina <page>",
      at: [pdf.bounds.left, 30],
      width: pdf.bounds.width,
      align: :center,
      size: 7
    )
  end



  def lugar_y_fecha(pdf)
    fecha_actual = I18n.l(Time.zone.today, format: :long)

    pdf.move_down 20
    pdf.text "Buenos Aires, #{fecha_actual}. -", size: 11, align: :right
    pdf.move_down 15
  end


  def introduccion(pdf)
    pdf.text(
      "El presente documento tiene el fin de resumir y guiar en la Convocatoria de Certificación SIAC-UTN bajo la denominación #{@convocatoria.nombre}, iniciada para la fecha de #{@convocatoria.fecha_inicio}, para dar cumplimiento a la implementación del Sistema Institucional de Aseguramiento de la Calidad establecido por la Resolución Ministerial N° 2597/2023. Dando realización a lo definido en la resolución #{@convocatoria.resolucion} del Consejo Superior de la UNIVERSIDAD TECNOLÓGICA NACIONAL.",
      size: 11,
      align: :justify,
      leading: 3
    )

    pdf.move_down 12
  end


  def objetivo(pdf)
    pdf.text "Objetivo de la convocatoria", style: :bold, size: 12
    pdf.move_down 6

    pdf.text(
      "El objetivo central es certificar la calidad académica de las carreras de Pregrado (Tecnicaturas), Grado (Licenciaturas y Ciclos de Complementación) e Ingenierías no comprendidas en el Art. 43 de la Ley de Educación Superior. Este proceso busca validar el cumplimiento de criterios de calidad y promover la mejora continua, asegurando la transparencia frente a la comunidad universitaria.",
      size: 11,
      align: :justify,
      leading: 3
    )

    pdf.move_down 15
  end


  def alcance(pdf)
    pdf.text "Alcance de esta convocatoria", style: :bold, size: 12
    pdf.move_down 6

    pdf.text(
      "Aplica a la carrera seleccionada independientemente de su modalidad de dictado (presencial o a distancia) y su sede o extensión áulica.",
      size: 11,
      align: :justify
    )

    pdf.move_down 15
  end


  def etapas(pdf)
    pdf.text "Etapas del proceso", style: :bold, size: 12
    pdf.move_down 12

    # ETAPA 1
    pdf.text "ETAPA 1: Capacitación y Habilitación de Usuarios hasta el [FECHA FIN ETAPA CAPACITACIÓN]",
            style: :bold, size: 11
    pdf.move_down 4
    pdf.text(
      "Es la fase inicial de preparación.\n" \
      "• Gestión de Accesos: Se entregarán las credenciales al Responsable de Carga designado.\n" \
      "• Creación de Equipo: El responsable será capacitado para crear y gestionar \"Usuarios de Soporte de Carga\" dentro del sistema.\n" \
      "Los usuarios de soporte pueden cargar y editar datos, pero NO tienen permiso para realizar el envío final de la presentación.\n" \
      "• Soporte: Se habilitarán canales de discusión exclusivos para resolver dudas funcionales y normativas.",
      size: 11,
      align: :justify,
      leading: 3
    )

    pdf.move_down 12

    # ETAPA 2
    pdf.text "ETAPA 2: Carga de Datos (Ventana Activa) hasta el [FECHA LÍMITE CARGA]",
            style: :bold, size: 11
    pdf.move_down 4
    pdf.text(
      "Es el período central donde las Facultades Regionales completan la información, autoevaluación y adjuntos.\n" ,
      size: 11,
      align: :justify,
      leading: 3
    )

    pdf.move_down 12

    # ETAPA 3
    pdf.text "ETAPA 3: Revisión Interna (Bloqueo Preventivo) hasta el [FECHA DE REVISION]",
            style: :bold, size: 11
    pdf.move_down 4
    pdf.text(
      "Una vez cerrada la carga, comienza la auditoría por parte del equipo técnico de Planeamiento.\n" \
      "• Estado del Usuario: Solo Lectura. Los usuarios cargadores no podrán subir nueva información ni editar la existente.\n" \
      "• Actividad: Recibirán notificaciones y comentarios de los auditores internos sobre inconsistencias o faltantes detectados.",
      size: 11,
      align: :justify,
      leading: 3
    )

    pdf.move_down 12

    # ETAPA 4
    pdf.text "ETAPA 4: Etapa de Correcciones (Interacción) hasta el [FECHA DE CORRECCIONES]",
            style: :bold, size: 11
    pdf.move_down 4
    pdf.text(
      "Se habilita una ventana de tiempo específica para subsanar lo detectado en la revisión anterior.\n" \
      "Dinámica Simultánea: Durante este lapso, conviven la edición por parte de la Regional (para corregir) y la auditoría continua del equipo interno. " \
      "Es el momento de ajustar el contenido antes de la evaluación final.",
      size: 11,
      align: :justify,
      leading: 3
    )

    pdf.move_down 12

    # ETAPA 5
    pdf.text "ETAPA 5: Auditoría Externa",
            style: :bold, size: 11
    pdf.move_down 4
    pdf.text(
      "El proceso pasa a manos del Comité de Pares Evaluadores.\n" \
      "• Estado del Usuario: Bloqueo Total de Edición. Las Facultades Regionales pierden definitivamente el poder de modificación sobre la convocatoria.\n" \
      "• Interacción de Auditores: Los auditores internos dejan sus notas técnicas para los auditores externos.\n" \
      "• Evaluación: Los externos revisan la información, validan las evidencias y generan sus propios comentarios, los cuales quedan registrados para el dictamen.",
      size: 11,
      align: :justify,
      leading: 3
    )

    pdf.move_down 12

    # ETAPA 6
    pdf.text "ETAPA 6: Dictamen Final",
            style: :bold, size: 11
    pdf.move_down 4
    pdf.text(
      "Etapa conclusiva administrativa.\n" \
      "• Resolución: El Área de Planeamiento consolida las evaluaciones internas y externas. Se procede a la emisión del Informe Final y el dictamen que resultará en una Resolución de Consejo Superior.\n" \
      "• Resultado: Se notifica la Aprobación (Certificación), Observación Estructural (Compromisos) o Rechazo (No Certificación).",
      size: 11,
      align: :justify,
      leading: 3
    )
  end



  def etapa(pdf, titulo, texto)
    pdf.text titulo, style: :bold, size: 11
    pdf.move_down 4
    pdf.text texto, size: 11, align: :justify, leading: 3
    pdf.move_down 10
  end

  def responsables_y_proceso(pdf)
    pdf.text(
      "Cada regional definirá su respectivo responsable de la carga, el mismo deberá gestionar las siguientes etapas obligatorias a través del sistema de gestión habilitado:",
      size: 11,
      align: :justify
    )

    pdf.move_down 10
    pdf.text "A. Carga de Información y Autoevaluación", style: :bold, size: 11
    pdf.text(
      "Deberá completar la información requerida en las siguientes Dimensiones de Análisis:",
      size: 11,
      align: :justify
    )

    lista = [
      "Dimensión Curricular: Diseño, planes de estudio y su alineación con el perfil profesional.",
      "Actividad Docente: Calidad del cuerpo docente, selección y capacitación.",
      "Estudiantado: Acceso, regularidad, promoción y apoyo académico.",
      "Desarrollo Académico: Análisis de trayectos y tasas de graduación.",
      "Organizacional: Infraestructura, recursos y mecanismos de gestión."
    ]

    lista.each do |item|
      pdf.text "• #{item}", size: 11, indent_paragraphs: 20
    end

    pdf.move_down 10
    pdf.text "B. Formulación de Acciones de Mejora", style: :bold, size: 11
    pdf.text(
      "Basado en la autoevaluación, es obligatorio proponer acciones para subsanar debilidades detectadas. Estas deben incluir objetivos claros, responsables, recursos necesarios y cronogramas.",
      size: 11,
      align: :justify
    )

    pdf.move_down 10
    pdf.text "C. Validación Externa", style: :bold, size: 11
    pdf.text(
      "La información cargada será auditada por un Comité de Evaluación Externa e Interna. Tenga en cuenta que se realizarán espacios de intercambio y validación (entrevistas y verificación de instalaciones) para corroborar la veracidad de los datos presentados.",
      size: 11,
      align: :justify
    )

    pdf.move_down 15
  end

  def impacto_y_resultados(pdf)
    pdf.text(
      "La calidad y veracidad de la carga de datos impactan directamente en el futuro operativo de la carrera. " \
      "El Consejo Superior emitirá una resolución basada en el Informe Final con tres posibles resultados:",      
      size: 11,
      align: :justify
    )

    pdf.move_down 10
  end

  def tabla_resultados(pdf)
    data = [
      ["Resultado", "Vigencia (Lic. e Ing.)", "Vigencia (Tecnicaturas)", "Implicancia Operativa"],
      ["Certificación Plena", "6 Años", "4 Años", "Cumple criterios de calidad sin observaciones estructurales."],
      ["Certificación con Compromisos", "3 Años", "2 Años", "Requiere ejecutar planes de mejora obligatorios."],
      ["No Certificación", "0 Años", "0 Años", "Se restringe la apertura de nuevas cohortes."]
    ]

    pdf.table(data, width: pdf.bounds.width) do
      row(0).font_style = :bold
      self.cell_style = { size: 10, padding: 6 }
    end

    pdf.move_down 10

    pdf.text(
      "IMPORTANTE: Una carga de datos incompleta, errónea o la falta de planes de mejora viables puede derivar en la No Certificación, impidiendo la inscripción de nuevos estudiantes en los ciclos lectivos siguientes.",
      size: 11,
      align: :justify,
      style: :bold
    )

    pdf.move_down 15
  end

  def ciclo_de_vida(pdf)
    pdf.text(
      "Dentro del ciclo de vida general de la convocatoria dando inicio el #{@convocatoria.fecha_inicio} hasta el día #{@convocatoria.fecha_hasta}, el sistema gestionará una serie de etapas secuenciales que habilitan o restringen acciones específicas. Es vital que los equipos conozcan en qué fase se encuentran para gestionar sus tiempos.",
      size: 11,
      align: :justify
    )

    pdf.move_down 15
  end

  def explicacion_uso(pdf)
   
    pdf.text "Uso del Sistema de Gestión SIAC-UTN",
            style: :bold,
            size: 12
    pdf.move_down 10

    pdf.text(
      "Para completar las componentes dentro de las dimensiones de la convocatoria, la plataforma desplegará diferentes tipos de campos según la dimensión que se esté evaluando. A continuación, se detalla el uso correcto de cada uno para asegurar que la información sea procesada exitosamente por el Comité Evaluador.",
      size: 11,
      align: :justify,
      leading: 3
    )

    pdf.move_down 15

    # =============================
    # A. TIPOS DE CAMPOS
    # =============================
    pdf.text "A. Tipos de Campos de Ingreso de Datos",
            style: :bold,
            size: 11
    pdf.move_down 8

    campo(pdf,
          "Campo de texto",
          "Uso: Destinado a descripciones cualitativas, justificaciones de autoevaluación y explicaciones detalladas.",
          [
            "Recomendación: sea sintético y preciso. Dispone de aproximadamente 300 a 400 palabras.",
            "Si la información excede este límite, resuma los puntos clave y utilice la opción de “Adjuntar Archivos” para subir el documento extendido."
          ])

    campo(pdf,
          "Selección Única",
          "Uso: Se utiliza para respuestas excluyentes (Ej: “¿La carrera posee coordinador designado? SI/NO”).",
          [
            "Advertencia: Solo podrá elegir una opción.",
            "Verifique bien antes de avanzar, ya que puede definir la lógica de las preguntas siguientes o la obligatoriedad de los campos."
          ])

    campo(pdf,
          "Selección Múltiple",
          "Uso: Permite elegir varias opciones simultáneamente dentro de un listado.",
          [
            "Ejemplo: “Seleccione los recursos disponibles en el aula: Proyector, PC, Aire Acondicionado…”.",
            "Recomendación: Marque todas las opciones que correspondan a la realidad de la carrera."
          ])

    campo(pdf,
          "Campo Número",
          "Uso: Exclusivo para datos cuantitativos e indicadores.",
          [
            "Ejemplos: Cantidad de inscriptos, Tasa de graduación, Metros cuadrados.",
            "Formato: Ingrese solo valores numéricos, sin texto ni símbolos."
          ])

    campo(pdf,
          "Campo Fecha",
          "Uso: Fundamental para la sección de Planes de Mejora.",
          [
            "Se utilizará para establecer los hitos de cumplimiento y fechas límite.",
            "Las fechas ingresadas constituyen compromisos que serán auditados en el futuro."
          ])

    pdf.move_down 15

    # =============================
    # B. RESPALDO DOCUMENTAL
    # =============================
    pdf.text "B. Respaldo Documental",
            style: :bold,
            size: 11
    pdf.move_down 8

    pdf.text(
      "Opción: Adjuntar archivos.\n" \
      "Uso: Es el repositorio de EVIDENCIA. Utilícelo para cargar Resoluciones, Planes de Estudio, Convenios firmados o fotografías de instalaciones.\n" \
      "Consejo: Todo dato crítico mencionado en un Campo de Texto o Campo Número debería contar con su respaldo documental para facilitar la validación externa.",
      size: 11,
      align: :justify,
      leading: 3
    )

    pdf.move_down 15

    # =============================
    # AUTOEVALUACIÓN
    # =============================
    pdf.text(
      "Una vez completada la carga de datos (componentes), se habilitará la pestaña de Autoevaluación. Esta instancia es el corazón del proceso SIAC-UTN, donde la carrera diagnostica su estado real y define su futuro mediante compromisos de gestión.",
      size: 11,
      align: :justify,
      leading: 3
    )

    pdf.move_down 10

    pdf.text(
      "El sistema solicitará completar tres bloques de información para cada criterio evaluado:",
      size: 11,
      style: :bold
    )

    pdf.move_down 8

    autoevaluacion_bloque(
      pdf,
      "A. Nivel de Cumplimiento / Calidad (Selector de Porcentaje)",
      [
        "Alto Cumplimiento: Indica una fortaleza con evidencias sólidas.",
        "Cumplimiento Parcial o Bajo: Indica una debilidad o Área de Vacancia.",
        "Para niveles bajos se espera una Acción de Mejora robusta; para niveles altos, un Plan de Continuidad y Crecimiento."
      ]
    )

    autoevaluacion_bloque(
      pdf,
      "B. Descripción / Justificación",
      [
        "Debe fundamentar la calificación seleccionada.",
        "No es una repetición de datos: es un análisis cualitativo.",
        "Explique coherentemente las fortalezas o debilidades detectadas."
      ]
    )

    autoevaluacion_bloque(
      pdf,
      "C. Propuesta de Mejoras (Plan de Acción)",
      [
        "Objetivo: Qué se va a lograr.",
        "Responsables: Quién ejecutará la mejora.",
        "Recursos: Inversión o capital humano requerido.",
        "Cronograma: Plazos de ejecución."
      ]
    )
  end


  def campo(pdf, titulo, descripcion, bullets)
    pdf.text titulo, style: :bold, size: 11
    pdf.move_down 4

    pdf.text descripcion, size: 11, align: :justify, leading: 3
    pdf.move_down 4

    bullets.each do |b|
      pdf.text "• #{b}", size: 11, indent_paragraphs: 20
    end

    pdf.move_down 10
  end

  def autoevaluacion_bloque(pdf, titulo, bullets)
    pdf.text titulo, style: :bold, size: 11
    pdf.move_down 4

    bullets.each do |b|
      pdf.text "• #{b}", size: 11, indent_paragraphs: 20
    end

    pdf.move_down 10
  end



 private

 def convocatoria_params
  params.require(:convocatoria).permit(
   :resolucion, :nombre, :fecha_inicio, :fecha_hasta, :titulaciones, :etapa, :estado,
   sedes_codigos: [], componentes_codigos: [], especialidad_ids: [] # <-- permit IDs
  )
 end
end
