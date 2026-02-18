require 'prawn'
require 'prawn/table'

class ConvocatoriaController < ApplicationController
  include Siac::ControllerGuard

  before_action :deny_siac_cliente!
  
  helper ComponenteHelper
  include ConvocatoriaHelper

  before_action :load_titulaciones, only: [:edit, :update]

  def load_titulaciones
    @titulaciones = [
      ['Carrera de Grado', 3],
      ['Ciclo de Licenciatura', 11],
      ['Tecnico Superior', 12],
      ['Maestría', 5],
      ['Doctorado', 6]
    ]
  end
  private :load_titulaciones

  
  ComponenteDto = Struct.new(:id, :nombre, :dimension_id, keyword_init: true)
  
  def new
    preparar_form_nueva_convocatoria
    render :new
  end

  def cargar_especialidades
    tipo = params[:id].presence || params[:titulacion].presence

    Rails.logger.info("[SIAC] cargar_especialidades ENTER tipo=#{tipo.inspect} params=#{params.to_unsafe_h.inspect}")

    return render(json: { error: "tipo_especialidad requerido" }, status: :bad_request) if tipo.blank?

    rows = Siac::SiacRepository.query(
      Siac::SiacRepository.send(
        :sanitize_sql_array,
        [%Q{
          SELECT id_especialidad, letra, nombre
          FROM public."SPYP_Especialidades"
          WHERE tipo_especialidad = ?
            AND activa = B'1'
          ORDER BY nombre
        }, tipo.to_i]
      )
    )

    Rails.logger.info("[SIAC] cargar_especialidades rows=#{rows.size}")

    render partial: "especialidades", locals: { especialidades: rows }
  end


  def cargar_sedes
    especialidad_ids = Array(params[:especialidades]).reject(&:blank?).map(&:to_i).uniq
    return render partial: "sedes", locals: { sedes: [] } if especialidad_ids.empty?

    sedes_by_id = {}

    especialidad_ids.each do |especialidad_id|
      rows = Siac::SiacRepository.query(
        Siac::SiacRepository.send(
          :sanitize_sql_array,
          [%Q{ SELECT * FROM SIAC_BUSCAR_UNIDADES_ACADEMICAS_X_CARRERA(?) }, especialidad_id]
        )
      )

      rows.each do |r|
        id_facultad = r["id_facultad"]
        sedes_by_id[id_facultad] ||= {
          id_facultad: id_facultad,
          nombre: r["nombre"],
          extensiones: r["extensiones"]
        }
      end
    end

    render partial: "sedes", locals: { sedes: sedes_by_id.values }
  end


  def cerrar_vencidas_siac(today)
    cerrada_id = Siac::SiacRepository.query(%Q{
      SELECT id_estado_convocatoria
      FROM public."SIAC_EstadosConvocatorias"
      WHERE nombre_estado = 'Cerrada'
      LIMIT 1
    }).dig(0, "id_estado_convocatoria")

    return if cerrada_id.blank?

    vencidas = Siac::SiacRepository.query(
      Siac::SiacRepository.send(
        :sanitize_sql_array,
        [%Q{
          SELECT id_convocatoria
          FROM public."SIAC_Convocatorias"
          WHERE fecha_fin_convocatoria < ?
            AND id_estado_actual <> ?
        }, today, cerrada_id]
      )
    )

    vencidas.each do |row|
      Siac::SiacRepository.procedure(
        "SIAC_ACTUALIZAR_ESTADO_CONVOCATORIAS",
        nil,
        row["id_convocatoria"].to_i,
        cerrada_id.to_i
      )
    end
  end

  def index
    require "date"

    # Traer todo (no solo activas), y luego filtrar canceladas
    rows = Siac::SiacRepository.function_typed(
      "public.siac_buscar_convocatorias_x_parametros",
      [
        { value: false, cast: "boolean" }, # i_solo_activas
        { value: nil,   cast: "int" },     # i_estado_actual
        { value: nil,   cast: "date" },    # i_fecha_desde
        { value: nil,   cast: "date" }     # i_fecha_hasta
      ]
    )

    # Filtrar las canceladas
    rows = rows.reject do |r|
      r["nombre_estado_actual"].to_s.strip.downcase == "cancelada"
    end

    # Buscador
    q = params[:q].to_s.strip.downcase
    if q.present?
      rows = rows.select do |r|
        r["numero_resolucion"].to_s.downcase.include?(q) ||
          r["nombre_convocatoria"].to_s.downcase.include?(q)
      end
    end

    dtos = rows.map do |r|
      Siac::ConvocatoriaDto.new(
        id: r["id_convocatoria"],
        resolucion: r["numero_resolucion"],
        nombre: r["nombre_convocatoria"],
        fecha_inicio: parse_date(r["fecha_inicio_convocatoria"]),
        fecha_hasta:  parse_date(r["fecha_fin_convocatoria"]),
        titulaciones: r["id_tipo_especialidad"],
        tipo_especialidad: r["tipo_especialidad"],
        etapa:  (r["nombre_estado_actual"].presence || "Nueva"),
        estado: (r["nombre_estado_actual"])
      )
    end


    dtos.sort_by! { |x| [x.fecha_inicio || Date.new(1900,1,1), x.id.to_i] }
    dtos.reverse!

    @convocatoria = Kaminari.paginate_array(dtos).page(params[:page]).per(5)
  end


  def create
    # 1) params tolerantes: si viene scope :convocatoria OK, si no, fallback
    raw = params[:convocatoria].presence || params

    # 2) Campos base
    numero_res = raw[:resolucion].to_s.strip
    nombre     = raw[:nombre].to_s.strip
    tipo_esp   = raw[:titulaciones].to_i

    # Fechas
    f_ini = parse_date_param(raw[:fecha_inicio])
    f_fin = parse_date_param(raw[:fecha_hasta])

    # 3) Arrays: soporta ambas formas de nombres (convocatoria[...][] o sueltos)
    especialidades =
      Array(raw[:especialidad_ids]).presence ||
      Array(params[:especialidad_ids])

    componentes =
      Array(raw[:componentes_codigos]).presence ||
      Array(params[:componentes_codigos])

    sedes =
      Array(raw[:sedes_codigos]).presence ||
      Array(params[:sedes_codigos])

    especialidades = Array(especialidades).reject(&:blank?).map(&:to_i).uniq
    componentes    = Array(componentes).reject(&:blank?).map(&:to_i).uniq
    regionales     = Array(sedes).reject(&:blank?).map(&:to_i).uniq

    # 4) Validaciones mínimas (ajustá si querés)
    errores = []
    errores << "La resolución es obligatoria." if numero_res.blank?
    errores << "El nombre es obligatorio." if nombre.blank?
    errores << "La titulación es obligatoria." if tipo_esp <= 0
    errores << "La fecha de inicio es obligatoria." if f_ini.blank?
    errores << "La fecha de fin es obligatoria." if f_fin.blank?
    errores << "Seleccioná al menos una especialidad." if especialidades.empty?
    errores << "Seleccioná al menos una sede." if regionales.empty?
    errores << "Seleccioná al menos un componente." if componentes.empty?

    if errores.any?
      flash.now[:error] = errores.join(" ")
      preparar_form_nueva_convocatoria
      return render :new
    end


    # 5) Fechas intermedias: tu UI las valida, pero la SP las requiere.
    # Usamos los valores de UI si están, sino colapsamos a f_fin.
    # (si no tenés estos campos en el form, raw[...] será nil)
    f_fin_capacitacion = parse_date_param(raw[:fecha_fin_capacitacion]) || f_fin
    f_fin_carga        = parse_date_param(raw[:fecha_fin_carga])        || f_fin
    f_fin_revision     = parse_date_param(raw[:fecha_fin_revision])     || f_fin
    f_fin_correcciones = parse_date_param(raw[:fecha_fin_correcciones]) || f_fin
    f_fin_auditoria    = parse_date_param(raw[:fecha_fin_auditoria])    || f_fin

    # 6) Sedes: hoy mandás sólo regionales. Extensiones queda nil.
    extensiones = nil

    # 7) Usuario
    user_id = User.current.id

    Rails.logger.info("[SIAC][CREATE] res=#{numero_res.inspect} nombre=#{nombre.inspect} tipo=#{tipo_esp} user=#{user_id} " \
                      "ini=#{f_ini} fin=#{f_fin} esp=#{especialidades.size} comp=#{componentes.size} sedes=#{regionales.size}")

    # 8) Llamada a SP
    resultado = nil
        begin
    resultado = nil

    typed = [
      { value: resultado, cast: "integer" },                         # INOUT p_resultado
      { value: numero_res, cast: "character varying" },
      { value: nombre,     cast: "character varying" },
      { value: tipo_esp,   cast: "integer" },
      { value: user_id,    cast: "integer" },
      { value: f_ini,      cast: "date" },
      { value: f_fin_capacitacion, cast: "date" },
      { value: f_fin_carga,        cast: "date" },
      { value: f_fin_revision,     cast: "date" },
      { value: f_fin_correcciones, cast: "date" },
      { value: f_fin_auditoria,    cast: "date" },
      { value: f_fin,              cast: "date" },

      # Arrays -> literal + cast
      { value: Siac::SiacRepository.pg_int_array_literal(especialidades), cast: "integer[]" },
      { value: Siac::SiacRepository.pg_int_array_literal(componentes),    cast: "integer[]" },
      { value: Siac::SiacRepository.pg_int_array_literal(regionales),     cast: "integer[]" },

      # extensiones: varchar[] o NULL
      { value: Siac::SiacRepository.pg_varchar_array_literal(extensiones), cast: "character varying[]" }
    ]

    resultado = Siac::SiacRepository.procedure_typed(
      "public.siac_insertar_convocatorias",
      typed
    )
    rescue => e
      Rails.logger.error("[SIAC][CREATE] ERROR procedure: #{e.class}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      flash.now[:error] = "Error al crear la convocatoria (procedure)."
      preparar_form_nueva_convocatoria
      return render :new
    end

    # 9) Normalizar retorno (Array/Hash/scalar)
    row =
      if resultado.is_a?(Array)
        resultado.first
      else
        resultado
      end

    new_id =
      if row.is_a?(Hash)
        row["p_resultado"] || row[:p_resultado] || row["resultado"] || row[:resultado]
      else
        row
      end

    new_id_i = new_id.to_i

    Rails.logger.info("[SIAC][CREATE] procedure resultado=#{resultado.inspect} new_id=#{new_id.inspect} new_id_i=#{new_id_i}")

    if new_id_i > 0
      redirect_to convocatorias_path, notice: "Convocatoria creada con éxito."
    else
      flash.now[:error] = "No se pudo crear la convocatoria."
      preparar_form_nueva_convocatoria
      render :new
    end
  end


  def destroy
    id = params[:id].to_i

    cancelada_id = siac_estado_id("Cancelada") || siac_estado_id("Cerrada")
    return redirect_to(convocatorias_path, alert: "No existe estado Cancelada/Cerrada en SIAC_EstadosConvocatorias") if cancelada_id.blank?

    res = Siac::SiacRepository.procedure(
      "public.siac_actualizar_estado_convocatorias",
      nil,
      id,
      cancelada_id.to_i
    )

    row = res.is_a?(Array) ? res.first : res
    ok = row.is_a?(Hash) ? row["p_resultado"].to_i == 1 : row.to_i == 1

    if ok
      redirect_to convocatorias_path, notice: "Convocatoria cancelada correctamente."
    else
      redirect_to convocatorias_path, alert: "Error al cancelar la convocatoria."
    end
  end



  def preview
    id = params[:id].to_i

    # 1) Convocatoria (si la usás arriba del template)
    @convocatoria = Siac::SiacRepository.query(
      Siac::SiacRepository.send(
        :sanitize_sql_array,
        [%Q{
          SELECT c.*,
                e.nombre_estado
          FROM public."SIAC_Convocatorias" c
          JOIN public."SIAC_EstadosConvocatorias" e
            ON e.id_estado = c.id_estado_actual
          WHERE c.id_convocatoria = ?
          LIMIT 1
        }, id]
      )
    ).first

    # 2) Dimensiones del set de componentes de esta convocatoria
    @dimensiones = Siac::SiacRepository.query(
      Siac::SiacRepository.send(
        :sanitize_sql_array,
        [%Q{
          SELECT DISTINCT d.id_dimension, d.nombre
          FROM public."SIAC_ConvocatoriasXComponentes" cx
          JOIN public."SIAC_Componentes" c ON c.id_componente = cx.id_componente
          JOIN public."SIAC_Dimensiones" d ON d.id_dimension = c.id_dimension
          WHERE cx.id_convocatoria = ?
          ORDER BY d.id_dimension
        }, id]
      )
    )

    # 3) Componentes (los que pintás como tabs)
    @componentes = Siac::SiacRepository.query(
      Siac::SiacRepository.send(
        :sanitize_sql_array,
        [%Q{
          SELECT d.id_dimension,
                d.nombre AS nombre_dimension,
                c.id_componente,
                c.nombre AS nombre_componente
          FROM public."SIAC_ConvocatoriasXComponentes" cx
          JOIN public."SIAC_Componentes" c ON c.id_componente = cx.id_componente
          JOIN public."SIAC_Dimensiones" d ON d.id_dimension = c.id_dimension
          WHERE cx.id_convocatoria = ?
          ORDER BY d.id_dimension, c.id_componente
        }, id]
      )
    )

    # 4) Campos asociados a la convocatoria (función)
    campos_rows = Siac::SiacRepository.query(
      Siac::SiacRepository.send(:sanitize_sql_array, [%Q{
        SELECT * FROM SIAC_BUSCAR_CAMPOS_CONVOCATORIAS(?)
      }, id])
    )

    # 5) Tipos de campo (clave para render_field_for)
    tipos_rows = Siac::SiacRepository.query(%Q{
      SELECT id_tipo, nombre, descripcion, activo
      FROM public."SIAC_TiposCampo"
    })

    tipos_por_id = tipos_rows.each_with_object({}) do |t, h|
      h[t["id_tipo"].to_i] = OpenStruct.new(
        id: t["id_tipo"].to_i,
        nombre: t["nombre"],
        descripcion: t["descripcion"],
        activo: (t["activo"].to_s == "1")
      )
    end

    # 6) Opciones por campo (para selección única/múltiple)
    campo_ids = campos_rows.map { |r| r["id_campo"].to_i }.uniq
    opciones_por_campo = Hash.new { |h, k| h[k] = [] }

    if campo_ids.any?
      opciones_rows = Siac::SiacRepository.query(
        Siac::SiacRepository.send(
          :sanitize_sql_array,
          [%Q{
            SELECT id_opcion, id_campo, nombre_opcion, activo
            FROM public."SIAC_OpcionesCampo"
            WHERE id_campo IN (?)
            ORDER BY id_campo, id_opcion
          }, campo_ids]
        )
      )

      opciones_rows.each do |op|
        opciones_por_campo[op["id_campo"].to_i] << op
      end
    end

    # 7) Armar estructura: @campos_por_componente[componente_id] = [campo1, campo2...]
    @campos_por_componente = Hash.new { |h, k| h[k] = [] }

    campos_rows.each do |r|
      campo_id = r["id_campo"].to_i
      comp_id  = r["id_componente"].to_i

      campo = OpenStruct.new(
        id: campo_id,
        id_campo: campo_id,
        id_componente: comp_id,

        nombre: r["nombre_campo"],
        nombre_campo: r["nombre_campo"],
        pregunta: r["pregunta_orientadora"],
        pregunta_orientadora: r["pregunta_orientadora"],

        es_obligatorio: (r["es_obligatorio"].to_s == "1"),
        permite_archivos: (r["permite_archivos"].to_s == "1"),
        autoevaluacion: (r["es_autovaluacion"].to_s == "1") ? 1 : 0,

        id_tipo_campo: r["id_tipo_campo"].to_i,
        tipo_campo: tipos_por_id[r["id_tipo_campo"].to_i],

        id_campo_padre: r["id_campo_padre"]&.to_i,
        activo: (r["activo"].to_s == "1"),

        # esto es lo que tu helper normalize_opciones usa primero:
        opciones_campos: Array(opciones_por_campo[campo_id]).map do |op|
          OpenStruct.new(
            id: op["id_opcion"].to_i,
            nombre_opcion: op["nombre_opcion"],
            activo: (op["activo"].to_s == "1")
          )
        end
      )

      @campos_por_componente[comp_id] << campo
    end
  end




  def show
    id = params[:id].to_i

    # 1) Traer convocatoria + estado (join)
    row = Siac::SiacRepository.query(
      Siac::SiacRepository.send(
        :sanitize_sql_array,
        [%Q{
          SELECT c.id_convocatoria,
                c.numero_resolucion,
                c.nombre_convocatoria,
                c.id_tipo_especialidad,
                c.fecha_inicio_convocatoria,
                c.fecha_fin_convocatoria,
                e.nombre_estado AS nombre_estado_actual
          FROM public."SIAC_Convocatorias" c
          JOIN public."SIAC_EstadosConvocatorias" e ON e.id_estado = c.id_estado_actual
          WHERE c.id_convocatoria = ?
          LIMIT 1
        }, id]
      )
    ).first

    return redirect_to(convocatorias_path, alert: "No existe la convocatoria") if row.blank?

    # 2) Construir objeto para la vista (NO hash)
    @convocatoria = OpenStruct.new(
      id: row["id_convocatoria"],
      resolucion: row["numero_resolucion"],
      nombre: row["nombre_convocatoria"],
      titulaciones: row["id_tipo_especialidad"],
      fecha_inicio: parse_date(row["fecha_inicio_convocatoria"]),
      fecha_hasta:  parse_date(row["fecha_fin_convocatoria"]),
      etapa: (row["nombre_estado_actual"].presence || "Nueva"),
      estado: row["nombre_estado_actual"]
    )

    # 3) Sedes (regionales + extensiones) para la tabla del show
    #    La vista espera: sede.nombre y sede.regional&.nombre / sede.regional&.id
    sedes_rows = Siac::SiacRepository.query(
      Siac::SiacRepository.send(
        :sanitize_sql_array,
        [%Q{
          SELECT
            r.id_facultad   AS regional_id,
            r.nombre        AS regional_nombre,
            x.id_extension  AS extension_id,
            x.nombre        AS extension_nombre
          FROM public."SIAC_Convocatorias" c
          LEFT JOIN public."SIAC_ConvocatoriasXRegionales"  cr ON cr.id_convocatoria = c.id_convocatoria
          LEFT JOIN public."SPYP_Regionales"                r  ON r.id_facultad = cr.id_facultad
          LEFT JOIN public."SIAC_ConvocatoriasXExtensiones" cx ON cx.id_convocatoria = c.id_convocatoria
          LEFT JOIN public."SPYP_ExtensionesAulicas"        x  ON x.id_extension = cx.id_extension
          WHERE c.id_convocatoria = ?
          ORDER BY r.nombre NULLS LAST, x.nombre NULLS LAST
        }, id]
      )
    )

    sedes = sedes_rows.map do |sr|
      regional =
        if sr["regional_id"].present?
          OpenStruct.new(id: sr["regional_id"].to_i, nombre: sr["regional_nombre"])
        end

      # Si hay extensión, mostramos la extensión; si no, mostramos "-" (pero mantenemos regional)
      OpenStruct.new(
        id: (sr["extension_id"] || sr["regional_id"]).to_i,
        nombre: (sr["extension_nombre"].presence || "-"),
        regional: regional
      )
    end

    # Evitar duplicados por joins (mismo regional/extensión repetidos)
    sedes.uniq! { |s| [s.regional&.id, s.nombre] }

    # 4) Usuarios por regional (esto depende de tu modelo/local DB)
    #    Tu vista usa @clientes_por_regional[regional_id] => usuario (con firstname/lastname)
    regional_ids = sedes.map { |s| s.regional&.id }.compact.uniq

    # Ajustá esta parte a tu modelo real. Te dejo una implementación segura:
    @clientes_por_regional = {}

    # 5) Paginación como espera la vista
    @sedes = Kaminari.paginate_array(sedes).page(params[:page]).per(10)
  end



  def edit
    id = params[:id].to_i

    @titulaciones = [
      ['Carrera de Grado', 3],
      ['Ciclo de Licenciatura', 11],
      ['Tecnico Superior', 12],
      ['Maestría', 5],
      ['Doctorado', 6]
    ]

    row = Siac::SiacRepository.query(
      Siac::SiacRepository.send(
        :sanitize_sql_array,
        [%Q{
          SELECT id_convocatoria,
                numero_resolucion,
                nombre_convocatoria,
                id_tipo_especialidad,
                fecha_inicio_convocatoria,
                fecha_fin_capacitacion,
                fecha_fin_carga,
                fecha_fin_revision,
                fecha_fin_correcciones,
                fecha_fin_auditoria,
                fecha_fin_convocatoria
          FROM public."SIAC_Convocatorias"
          WHERE id_convocatoria = ?
          LIMIT 1
        }, id]
      )
    ).first

    return redirect_to(convocatorias_path, alert: "No existe la convocatoria") if row.blank?

    @convocatoria = OpenStruct.new(
      id: row["id_convocatoria"],
      resolucion: row["numero_resolucion"],
      nombre: row["nombre_convocatoria"],
      titulaciones: row["id_tipo_especialidad"],
      fecha_inicio: row["fecha_inicio_convocatoria"],
      fecha_hasta: row["fecha_fin_convocatoria"],
      fecha_fin_capacitacion: row["fecha_fin_capacitacion"],
      fecha_fin_carga: row["fecha_fin_carga"],
      fecha_fin_revision: row["fecha_fin_revision"],
      fecha_fin_correcciones: row["fecha_fin_correcciones"],
      fecha_fin_auditoria: row["fecha_fin_auditoria"]
    )

    # Solo para mostrar (NO editable): detalle texto
    @detalle = Siac::SiacRepository.query(
      Siac::SiacRepository.send(:sanitize_sql_array, [%Q{ SELECT * FROM SIAC_BUSCAR_DETALLE_CONVOCATORIA(?) }, id])
    ).first

    render :edit
  end



  def update
    id = params[:id].to_i

    p = params.require(:convocatoria).permit(
      :resolucion, :nombre,
      :fecha_fin_capacitacion, :fecha_fin_carga, :fecha_fin_revision,
      :fecha_fin_correcciones, :fecha_fin_auditoria
    )

    # (Opcional) si también querés bloquear nombre/resolución, borrá estas 2 líneas
    numero_res = p[:resolucion].to_s.strip
    nombre     = p[:nombre].to_s.strip

    f_fin_capacitacion = parse_date_param(p[:fecha_fin_capacitacion])
    f_fin_carga        = parse_date_param(p[:fecha_fin_carga])
    f_fin_revision     = parse_date_param(p[:fecha_fin_revision])
    f_fin_correcciones = parse_date_param(p[:fecha_fin_correcciones])
    f_fin_auditoria    = parse_date_param(p[:fecha_fin_auditoria])

    user_id = User.current.id

    begin
      # Traigo inicio/fin “reales” para:
      # 1) no modificarlos
      # 2) validar rangos de intermedias
      base = Siac::SiacRepository.query(
        Siac::SiacRepository.send(
          :sanitize_sql_array,
          [%Q{
            SELECT fecha_inicio_convocatoria, fecha_fin_convocatoria
            FROM public."SIAC_Convocatorias"
            WHERE id_convocatoria = ?
            LIMIT 1
          }, id]
        )
      ).first

      return redirect_to(convocatorias_path, alert: "No existe la convocatoria") if base.blank?

      f_ini = parse_date(base["fecha_inicio_convocatoria"])
      f_fin = parse_date(base["fecha_fin_convocatoria"])

      # Validaciones básicas de negocio: intermedias dentro de [inicio, fin]
      intermedias = {
        "Capacitación" => f_fin_capacitacion,
        "Carga"        => f_fin_carga,
        "Revisión"     => f_fin_revision,
        "Correcciones" => f_fin_correcciones,
        "Auditoría"    => f_fin_auditoria
      }

      invalid = intermedias.select { |_k, v| v.blank? || v < f_ini || v > f_fin }
      if invalid.any?
        flash.now[:error] = "Fechas intermedias inválidas (deben estar entre #{f_ini} y #{f_fin})."
        @convocatoria = OpenStruct.new(id: id, resolucion: numero_res, nombre: nombre)
        return render :edit
      end

      # (Opcional) validar orden lógico entre intermedias
      ordered = [f_fin_capacitacion, f_fin_carga, f_fin_revision, f_fin_correcciones, f_fin_auditoria]
      if ordered != ordered.sort
        flash.now[:error] = "Las fechas intermedias deben estar en orden cronológico."
        @convocatoria = OpenStruct.new(id: id, resolucion: numero_res, nombre: nombre)
        return render :edit
      end

      # Update SOLO de lo permitido.
      # Nota: NO tocamos id_tipo_especialidad, especialidades, sedes, componentes, inicio, fin.
      Siac::SiacRepository.query(
        Siac::SiacRepository.send(
          :sanitize_sql_array,
          [%Q{
            UPDATE public."SIAC_Convocatorias"
            SET numero_resolucion       = ?,
                nombre_convocatoria     = ?,
                id_usuario_modificacion = ?,
                fecha_fin_capacitacion  = ?,
                fecha_fin_carga         = ?,
                fecha_fin_revision      = ?,
                fecha_fin_correcciones  = ?,
                fecha_fin_auditoria     = ?
            WHERE id_convocatoria = ?
          },
            numero_res,
            nombre,
            user_id,
            f_fin_capacitacion,
            f_fin_carga,
            f_fin_revision,
            f_fin_correcciones,
            f_fin_auditoria,
            id
          ]
        )
      )

      redirect_to convocatorias_path, notice: "Convocatoria actualizada con éxito."
    rescue => e
      Rails.logger.error("[SIAC][UPDATE] ERROR: #{e.class}: #{e.message}")
      flash.now[:error] = "No se pudo actualizar la convocatoria."
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
    # 1) Tomar params de manera tolerante (con o sin scope convocatoria)
    raw = params[:convocatoria].presence || params

    # 2) Construir un objeto liviano con los campos que usa el PDF
    @convocatoria = OpenStruct.new(
      resolucion:      raw[:resolucion].to_s,
      nombre:          raw[:nombre].to_s,
      titulaciones:    raw[:titulaciones].to_s,
      fecha_inicio:    parse_date_param(raw[:fecha_inicio]),
      fecha_hasta:     parse_date_param(raw[:fecha_hasta]),

      # si después querés usar estos en el PDF:
      especialidad_ids: Array(raw[:especialidad_ids]).reject(&:blank?).map(&:to_i),
      sedes_codigos:    Array(raw[:sedes_codigos]).reject(&:blank?).map(&:to_i),
      componentes_codigos: Array(raw[:componentes_codigos]).reject(&:blank?).map(&:to_i)
    )

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
              filename: "Convocatoria_#{(@convocatoria.nombre.presence || 'preview')}.pdf",
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

  def siac_estado_id(nombre_estado)
    row = Siac::SiacRepository.query(
      Siac::SiacRepository.send(
        :sanitize_sql_array,
        [%Q{
          SELECT id_estado
          FROM public."SIAC_EstadosConvocatorias"
          WHERE nombre_estado = ?
          LIMIT 1
        }, nombre_estado]
      )
    ).first

    row && row["id_estado"]
  end


 private

 def preparar_form_nueva_convocatoria
    @convocatoria ||= OpenStruct.new

    @titulaciones = [
      ['Carrera de Grado', 3],
      ['Ciclo de Licenciatura', 11],
      ['Tecnico Superior', 12],
      ['Maestría', 5],
      ['Doctorado', 6]
    ]

    @especialidades ||= []

    @componentes = Siac::SiacRepository.query(%Q{
      SELECT id_componente, nombre, id_dimension
      FROM public."SIAC_Componentes"
      WHERE activo = B'1'
      ORDER BY id_dimension, id_componente
    }).map do |r|
      ComponenteDto.new(
        id: r["id_componente"],
        nombre: r["nombre"],
        dimension_id: r["id_dimension"]
      )
    end

    @sedes ||= []
  end

  def parse_date_param(v)
    return nil if v.blank?
    Date.parse(v.to_s)
  rescue ArgumentError
    nil
  end

 def parse_date(value)
    return value if value.is_a?(Date)
    return value.to_date if value.respond_to?(:to_date) # Time/DateTime/ActiveSupport
    return nil if value.blank?

    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end
  private :parse_date

 def convocatoria_params
    params.require(:convocatoria).permit(
        :resolucion, :nombre, :titulaciones,
        :fecha_inicio, :fecha_hasta,
        :fecha_fin_capacitacion, :fecha_fin_carga, :fecha_fin_revision,
        :fecha_fin_correcciones, :fecha_fin_auditoria,
        sedes_codigos: [], componentes_codigos: [], especialidad_ids: []
      )

 end
end
