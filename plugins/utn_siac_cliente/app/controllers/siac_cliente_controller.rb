class SiacClienteController < ApplicationController
  helper ComponenteHelper

  before_action :require_login
  before_action :require_siac_cliente_permission
  before_action :disable_project_search_context 

  def index
    @cliente = SiacCliente.find_by(
      user_id: User.current.id,
      activo: true
    )

    return render_403 unless @cliente

    items = []

    @cliente.convocatorias
            .where.not(estado: 'Cerrada')
            .order(fecha_hasta: :asc)
            .each do |convocatoria|
      convocatoria.especialidades.each do |especialidad|
        items << OpenStruct.new(
          convocatoria: convocatoria,
          especialidad: especialidad
        )
      end
    end

    @convocatoria_especialidades =
      Kaminari.paginate_array(items)
              .page(params[:page])
              .per(10)
  end

  def new
    @convocatoria = Convocatoria.find(params[:id])
    @especialidad = Especialidad.find(params[:especialidad_id])

    @dimensiones = Dimension
      .joins(componentes: :convocatorias)
      .where(convocatorias: { id: @convocatoria.id })
      .distinct
      .order(:id)

    componentes = @convocatoria
                    .componentes
                    .includes(:campos, :dimension)

    @componentes_por_dimension = componentes.group_by(&:dimension_id)

    # 🔹 NUEVO: materias SIAC (plan más actual)
    materias_raw = Siac::MateriasPorEspecialidad.call(@especialidad.id)

    materias_ordenadas = materias_raw.sort_by { |m| m['codigo_materia'].to_s }

    @materias = Kaminari.paginate_array(materias_ordenadas)
                        .page(params[:page])
                        .per(6)

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

end
