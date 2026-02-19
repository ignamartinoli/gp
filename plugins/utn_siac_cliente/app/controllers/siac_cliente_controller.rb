class SiacClienteController < ApplicationController
  helper ComponenteHelper

  before_action :require_login
  before_action :require_siac_cliente_permission
  before_action :disable_project_search_context 

  def index
    @cliente = SiacCliente.find_by(user_id: User.current.id, activo: true)
    return render_403 unless @cliente

    # 1) Traer convocatorias SIAC
    sql_conv = <<~SQL
      SELECT *
      FROM SIAC_BUSCAR_CONVOCATORIAS_X_PARAMETROS(TRUE, NULL, NULL, NULL)
    SQL

    convocatorias = SiacRecord.connection.exec_query(sql_conv).to_a

    # 2) Filtrar no cerradas (con fallback por typo de la función)
    convocatorias.reject! do |c|
      estado = (c['nombre_estado_actual'] || c['nombre_estado_actua'])
      ['Cerrada', 'Cancelada'].include?(estado)
    end


    # 3) Traer especialidades por convocatoria
    ids = convocatorias.map { |c| c['id_convocatoria'].to_i }
    especialidades = []

    if ids.any?
      sql_esp = <<~SQL
        SELECT ce.id_convocatoria, e.id_especialidad, e.nombre
        FROM "SIAC_ConvocatoriasXEspecialidades" ce
        JOIN "SPYP_Especialidades" e ON e.id_especialidad = ce.id_especialidad
        WHERE ce.id_convocatoria = ANY($1::int[])
      SQL

      binds = [[nil, "{#{ids.join(',')}}" ]] # array literal para PG
      especialidades = SiacRecord.connection.exec_query(sql_esp, "SIAC", binds).to_a
    end

    # 4) Armar items (convocatoria × especialidad)
    esp_por_convo = especialidades.group_by { |r| r['id_convocatoria'].to_i }

    items = []
    convocatorias.each do |c|
      cid = c['id_convocatoria'].to_i
      (esp_por_convo[cid] || []).each do |e|
        items << OpenStruct.new(
          convocatoria: OpenStruct.new(
            id: cid,
            nombre: c['nombre_convocatoria'],
            fecha_hasta: to_date(c['fecha_fin_convocatoria']),
            etapa: (c['nombre_estado_actual'] || c['nombre_estado_actua'])
          ),
          especialidad: OpenStruct.new(
            id: e['id_especialidad'].to_i,
            nombre: e['nombre']
          )
        )
      end
    end

    @convocatoria_especialidades =
      Kaminari.paginate_array(items)
              .page(params[:page])
              .per(10)
  end



  def new
    convocatoria_id = params[:id].to_i
    especialidad_id = params[:especialidad_id].to_i

    # --- Convocatoria desde SIAC ---
    sql_conv = <<~SQL
      SELECT *
      FROM SIAC_BUSCAR_CONVOCATORIAS_X_PARAMETROS(NULL, NULL, NULL, NULL)
      WHERE id_convocatoria = $1
    SQL

    row = SiacRecord.connection.exec_query(sql_conv, "SIAC", [[nil, convocatoria_id]]).to_a.first
    return render_404 unless row

    @convocatoria = OpenStruct.new(
      id: row['id_convocatoria'].to_i,
      nombre: row['nombre_convocatoria'],
      numero_resolucion: row['numero_resolucion'],
      fecha_inicio: to_date(row['fecha_inicio_convocatoria']),
      fecha_hasta: to_date(row['fecha_fin_convocatoria']),
      etapa: row['nombre_estado_actual']
    )

    # --- Especialidad desde SIAC ---
    sql_espe = <<~SQL
      SELECT id_especialidad, nombre
      FROM "SPYP_Especialidades"
      WHERE id_especialidad = $1
    SQL
    erow = SiacRecord.connection.exec_query(sql_espe, "SIAC", [[nil, especialidad_id]]).to_a.first
    return render_404 unless erow

    @especialidad = OpenStruct.new(
      id: erow['id_especialidad'].to_i,
      nombre: erow['nombre']
    )

    # ============================================================
    # 1) COMPONENTES de la convocatoria (SIAC)
    # ============================================================
    sql_componentes = <<~SQL
      SELECT
        comp.id_componente,
        comp.id_dimension,
        comp.nombre,
        comp.descripcion,
        comp.activo
      FROM "SIAC_ConvocatoriasXComponentes" cc
      JOIN "SIAC_Componentes" comp ON comp.id_componente = cc.id_componente
      WHERE cc.id_convocatoria = $1
        AND comp.activo = 1::bit
      ORDER BY comp.id_dimension, comp.id_componente
    SQL

    componentes_rows = SiacRecord.connection.exec_query(sql_componentes, "SIAC", [[nil, convocatoria_id]]).to_a

    # ============================================================
    # 2) CAMPOS de la convocatoria (SIAC) + opciones
    # ============================================================
    sql_campos = <<~SQL
      SELECT *
      FROM SIAC_BUSCAR_CAMPOS_CONVOCATORIAS($1)
    SQL
    campos_rows = SiacRecord.connection.exec_query(sql_campos, "SIAC", [[nil, convocatoria_id]]).to_a

    # Opciones para campos múltiples
    campo_ids = campos_rows.map { |c| c['id_campo'].to_i }.uniq
    opciones_por_campo = {}

    if campo_ids.any?
      sql_opciones = <<~SQL
        SELECT id_opcion, id_campo, nombre_opcion, activo
        FROM "SIAC_OpcionesCampo"
        WHERE id_campo = ANY($1::int[])
          AND activo = 1::bit
        ORDER BY id_campo, id_opcion
      SQL

      # array literal seguro (ints)
      binds = [[nil, "{#{campo_ids.join(',')}}" ]]
      opciones = SiacRecord.connection.exec_query(sql_opciones, "SIAC", binds).to_a
      opciones_por_campo = opciones.group_by { |o| o['id_campo'].to_i }
    end

    # Agrupar campos por componente
    campos_por_componente = campos_rows.group_by { |c| c['id_componente'].to_i }

    # ============================================================
    # 3) DIMENSIONES (SIAC) sólo las que aparecen en componentes
    # ============================================================
    dimension_ids = componentes_rows.map { |r| r['id_dimension'].to_i }.uniq

    @dimensiones = []
    if dimension_ids.any?
      sql_dims = <<~SQL
        SELECT id_dimension, nombre, descripcion, activo
        FROM "SIAC_Dimensiones"
        WHERE id_dimension = ANY($1::int[])
          AND activo = 1::bit
        ORDER BY id_dimension
      SQL

      binds = [[nil, "{#{dimension_ids.join(',')}}" ]]
      dims_rows = SiacRecord.connection.exec_query(sql_dims, "SIAC", binds).to_a

      # OJO: tu vista usa dimension.dimension (no dimension.nombre)
      @dimensiones = dims_rows.map do |d|
        OpenStruct.new(
          id: d['id_dimension'].to_i,
          dimension: d['nombre'],       # <- para compatibilidad con la vista
          descripcion: d['descripcion']
        )
      end
    end

    # ============================================================
    # 4) Construir @componentes_por_dimension con objetos "compatibles"
    # ============================================================
    componentes_objs = componentes_rows.map do |r|
      comp_id = r['id_componente'].to_i

      campos_objs = (campos_por_componente[comp_id] || []).map do |c|
        cid = c['id_campo'].to_i

        OpenStruct.new(
          id: cid,
          componente_id: c['id_componente'].to_i,
          nombre: c['nombre_campo'],
          obligatorio: (c['es_obligatorio'].to_s == "1"),
          pregunta_orientadora: c['pregunta_orientadora'],
          tipo_campo_id: c['id_tipo_campo'].to_i,
          permite_archivos: (c['permite_archivos'].to_s == "1"),
          autoevaluacion: (c['es_autovaluacion'].to_s == "1") ? 1 : 0, # la vista usa .autoevaluacion.to_i
          campo_padre_id: c['id_campo_padre'],
          opciones: (opciones_por_campo[cid] || []).map { |o| OpenStruct.new(id: o['id_opcion'].to_i, nombre: o['nombre_opcion']) }
        )
      end

      OpenStruct.new(
        id: comp_id,
        dimension_id: r['id_dimension'].to_i,
        nombre: r['nombre'],
        descripcion: r['descripcion'],
        campos: campos_objs
      )
    end

    @componentes_por_dimension = componentes_objs.group_by(&:dimension_id)

    # ============================================================
    # 5) Lo que ya tenías (SIAC)
    # ============================================================
    materias_raw = Siac::MateriasPorEspecialidad.call(@especialidad.id)
    materias_ordenadas = materias_raw.sort_by { |m| m['codigo_materia'].to_s }
    @materias = Kaminari.paginate_array(materias_ordenadas).page(params[:page]).per(6)

    @grupos_investigacion  = Siac::GruposInvestigacion.call
    @centros_investigacion = Siac::CentrosInvestigacion.call
  end

  def create
    redirect_to siac_cliente_path, notice: 'Convocatoria enviada correctamente.'
  end

  def buscar_empresa
    cuit = params[:cuit].to_s.strip

    return render json: { error: 'CUIT inválido' }, status: 400 if cuit.blank?

    empresa = Siac::EmpresasRepository.buscar_por_cuit(cuit)

    if empresa
      render json: {
        nombre: empresa[:nombre]
      }
    else
      render json: { error: 'Empresa no encontrada' }, status: 404
    end
  end

  require 'net/http'
  require 'uri'
  require 'json'

  def buscar_empresa_nosis
    cuit = params[:cuit].to_s.strip
    return render json: { error: 'CUIT inválido' }, status: 400 if cuit.blank?

    uri = URI('https://informes.nosis.com/Home/Buscar')

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'
    request['Accept'] = '*/*'
    request['Origin'] = 'https://informes.nosis.com'
    request['Referer'] = 'https://informes.nosis.com/'
    request['User-Agent'] = 'Mozilla/5.0'

    request.set_form_data(
      'Texto' => cuit,
      'Tipo' => '-1',
      'EdadDesde' => '-1',
      'EdadHasta' => '-1',
      'IdProvincia' => '-1',
      'Localidad' => '',
      'recaptcha_response_field' => 'enganio al captcha',
      'recaptcha_challenge_field' => 'enganio al captcha',
      'encodedResponse' => ''
    )

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    response = http.request(request)

    data = JSON.parse(response.body) rescue {}

    razon_social =
      data.dig('EntidadesEncontradas', 0, 'RazonSocial')

    if razon_social.present?
      render json: { razon_social: razon_social }
    else
      render json: { error: 'Empresa no encontrada' }, status: 404
    end
  end



  private
  def disable_project_search_context
    @project = nil

    # Esto es lo que hace que el footer NO intente scoping
    @default_search_scope = nil
  end

  def require_siac_cliente_permission
    render_403 unless User.current&.siac_cliente?
  end

  def to_date(value)
    return value.to_date if value.respond_to?(:to_date)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

end
