class DocentesController < ApplicationController
  before_action :require_login
  include Siac::ControllerGuard

  # Mantener el guard original (define el callback)
  # before_action :deny_siac_cliente!

  # Permitimos que el cliente use estos endpoints del componente
  skip_before_action :deny_siac_cliente!, raise: false, only: %i[
    buscar datos catalogos guardar por_materia por_cuit
  ]

  # Autorización específica para SIAC Docentes (admin o cliente)
  before_action :authorize_siac_docentes!, only: %i[
    buscar datos catalogos guardar por_materia por_cuit
  ]

  def authorize_siac_docentes!
    # admin o usuario “cliente” (ajustá el predicate al que uses)
    allowed = User.current&.admin? || User.current&.siac_cliente?
    return if allowed

    render json: { ok: false, error: 'No autorizado' }, status: :forbidden
  end

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

  def por_materia
    cliente = SiacCliente.find_by(user_id: User.current.id, activo: true)
    return render json: { ok: false, error: 'Cliente no configurado' }, status: 422 unless cliente

    codigo = params[:codigo_materia].to_s.strip
    return render json: { ok: false, error: 'codigo_materia requerido' }, status: 400 if codigo.blank?

    docentes = Siac::DocentesRepository.docentes_por_materia(
      codigo_materia: codigo,
      id_facultad: cliente.regional_id
    )

    render json: { ok: true, docentes: docentes }
  end

  def por_cuit
    cliente = SiacCliente.find_by(user_id: User.current.id, activo: true)
    return render json: { ok: false, error: 'Cliente no configurado' }, status: 422 unless cliente

    cuil = (params[:cuil] || params[:cuit]).to_s.strip
    return render json: { ok: false, error: 'CUIT/CUIL inválido' }, status: 400 unless cuil =~ /^\d{11}$/

    codigo = params[:codigo_materia].to_s.strip.presence
    id_facultad = cliente.regional_id

    persona = Siac::DocentesRepository.docente_basico_por_cuit(cuil: cuil)
    return render json: { ok: true, found: false } unless persona

    ya_en_materia = false
    if codigo.present?
      ya_en_materia = Siac::DocentesRepository.cargo_activo_existente?(
        cuil: cuil,
        id_facultad: id_facultad,
        codigo_materia: codigo
      )
    end

    Rails.logger.warn("CV DEBUG id_cv_adjunto=#{persona['id_cv_adjunto'].inspect}")

    cv = nil
    if persona['id_cv_adjunto'].present?
      attachment = Attachment.find_by(id: persona['id_cv_adjunto'])

      if attachment.present?
        cv = {
          id: attachment.id,
          filename: attachment.filename,
          url: "/docentes/ver_cv?id=#{attachment.id}&cuil=#{CGI.escape(cuil)}"
        }
      end
    end

    render json: {
      ok: true,
      found: true,
      docente: {
        cuil: persona['cuil'],
        nombre: persona['nombre'],
        apellido: persona['apellido'],
        fecha_nacimiento: persona['fecha_nacimiento'],
        legajo: persona['legajo'],
        id_especialidad: persona['id_especialidad'],
        tipo_especialidad: persona['tipo_especialidad_recibido'],
        id_cv: persona['id_cv_adjunto']
      },
      cv: cv,
      ya_en_materia: ya_en_materia
    }
  rescue => e
    Rails.logger.error "[por_cuit] #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")

    render json: { ok: false, error: e.message }, status: 422
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
    Rails.logger.info '========== INICIO guardar =========='

    cliente = SiacCliente.find_by!(user_id: User.current.id, activo: true)
    id_facultad = cliente.regional_id

    docente = docente_params.to_h.symbolize_keys
    docente[:id_facultad] = id_facultad

    return render json: { ok: false, error: 'Titulación requerida' }, status: 422 if docente[:tipo_especialidad].blank?
    return render json: { ok: false, error: 'Especialidad inválida' }, status: 422 if docente[:id_especialidad].blank?

    archivo = params.dig(:docente, :cv)

    if archivo.present?
      resultado_cv = guardar_cv_redmine_desde_params!
      docente[:id_cv] = resultado_cv[:attachment_id]
    elsif docente[:id_cv].present?
      docente[:id_cv] = docente[:id_cv]
    else
      return render json: { ok: false, error: 'Debe adjuntar el CV en PDF' }, status: 422
    end

    unless Siac::DocentesRepository.docente_existe?(cuil: docente[:cuil])
      rows = Siac::DocentesRepository.insertar_docente_result(**docente)
      p_resultado = rows.first&.[]('p_resultado') || rows.first&.values&.first

      if p_resultado.present? && p_resultado.to_i != 1
        return render json: {
          ok: false,
          error: "SIAC_INSERTAR_DOCENTE rechazó (p_resultado=#{p_resultado})"
        }, status: 422
      end
    end

    cargo = cargo_params.to_h.symbolize_keys

    Siac::DocentesRepository.insertar_cargo_docente(
      codigo_materia: cargo[:codigo_materia],
      id_facultad: id_facultad,
      cuil: cargo[:cuil],
      fecha_asignacion: cargo[:fecha_asignacion],
      horas: cargo[:horas],
      id_cargo: cargo[:id_cargo],
      fecha_baja: cargo[:fecha_baja]
    )

    render json: {
      ok: true,
      id_cv: docente[:id_cv]
    }

  rescue => e
    Rails.logger.error "[guardar] #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")

    render json: { ok: false, error: e.message }, status: 422
  end


  # =========================
  # CATÁLOGO CARGOS DOCENTES
  # =========================
  def self.cargos_docentes_catalogo
      SiacRepository.query(
      'SELECT * FROM SIAC_OBTENER_CARGOS_DOCENTES'
      )
  end

  def ver_cv
    cliente = SiacCliente.find_by(user_id: User.current.id, activo: true)
    return render json: { ok: false, error: 'No autorizado' }, status: 403 unless cliente

    cuil = params[:cuil].to_s.strip
    attachment_id = params[:id].to_i

    persona = Siac::DocentesRepository.docente_basico_por_cuit(cuil: cuil)
    return render json: { ok: false, error: 'Docente no encontrado' }, status: 404 unless persona

    id_cv_adjunto = persona['id_cv_adjunto'].to_i
    return render json: { ok: false, error: 'No autorizado' }, status: 403 unless id_cv_adjunto == attachment_id

    attachment = Attachment.find_by(id: attachment_id)
    return render json: { ok: false, error: 'CV no encontrado' }, status: 404 unless attachment

    send_file(
      attachment.diskfile,
      filename: attachment.filename,
      type: attachment.content_type || 'application/pdf',
      disposition: 'inline'
    )
  end


  private

  def guardar_cv_redmine_desde_params!
    archivo = params.dig(:docente, :cv)

    raise 'Debe adjuntar el CV en PDF' if archivo.blank?
    raise 'El CV debe ser un archivo PDF' unless archivo.content_type == 'application/pdf'

    attachment = Attachment.new(
      file: archivo,
      author: User.current,
      filename: archivo.original_filename,
      content_type: 'application/pdf',
      description: 'CV docente'
    )

    unless attachment.save
      errores = attachment.errors.full_messages.to_sentence.presence || 'No se pudo guardar el CV en Redmine'
      raise errores
    end

    {
      attachment_id: attachment.id,
      filename: attachment.filename,
      disk_filename: attachment.disk_filename,
      filesize: attachment.filesize,
      content_type: attachment.content_type
    }
  end

  def docente_params
    params.require(:docente).permit(
      :cuil,
      :nombre,
      :apellido,
      :legajo,
      :fecha_nacimiento,
      :tipo_especialidad,
      :id_facultad,
      :id_especialidad,
      :id_cv,
      :cv
    )
  end

  def cargo_params
    params.require(:cargo).permit(
      :codigo_materia,
      :cuil,
      :fecha_asignacion,
      :horas,
      :id_cargo,
      :id_comision, 
      :fecha_baja
    ).to_h.symbolize_keys
  end

  def resolve_tipo_especialidad(id_especialidad)
    row = SiacRecord.connection.exec_query(<<~SQL, "SIAC", [[nil, id_especialidad]]).first
      SELECT tipo_especialidad
      FROM "SPYP_Especialidades"
      WHERE id_especialidad = $1
    SQL

    row && row["tipo_especialidad"]&.to_i
  end
end
