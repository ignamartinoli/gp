class ComponenteController < ApplicationController
  include Siac::ControllerGuard
  

  before_action :deny_siac_cliente!

  def index
    page     = params[:page].to_i
    page     = 1 if page <= 0
    per_page = 10
    offset   = (page - 1) * per_page

    total_sql = <<~SQL
      SELECT COUNT(*) AS total
      FROM siac_obtener_componentes
      WHERE activo = B'1'
    SQL

    rows_sql = <<~SQL
      SELECT id_componente, id_dimension, nombre, descripcion, activo
      FROM siac_obtener_componentes
      WHERE activo = B'1'
      ORDER BY id_dimension ASC, id_componente ASC
      LIMIT #{per_page}
      OFFSET #{offset}
    SQL

    total = Siac::SiacRepository.query(total_sql).first["total"].to_i
    rows  = Siac::SiacRepository.query(rows_sql)

    dtos = rows.map do |r|
      OpenStruct.new(
        id: r["id_componente"],
        dimension_id: r["id_dimension"],
        nombre: r["nombre"],
        descripcion: r["descripcion"],
        activo: r["activo"]
      )
    end

    @componentes = Kaminari.paginate_array(dtos, total_count: total)
                          .page(page)
                          .per(per_page)
  end

  def new
    @componente = Componente.new
    campo = @componente.campos.build
    campo.subcampos.build if campo.subcampos.empty?

    @dimensiones = fetch_dimensiones_convo
    @tipos_campo = fetch_tipos_campo
  end
  
  def create
    ActiveRecord::Base.transaction do
      # 1) Insertar componente
      Siac::SiacRepository.procedure(
        "SIAC_INSERTAR_COMPONENTES",
        nil,
        params.dig(:componente, :dimension_id).to_i,
        params.dig(:componente, :nombre).to_s,
        params.dig(:componente, :descripcion).to_s,
        "1" # BIT activo
      )

      # 2) Obtener id_componente (ideal: que el SP lo devuelva, pero por ahora hacemos esto)
      id_componente = Siac::SiacRepository
        .query('SELECT id_componente FROM "SIAC_Componentes" ORDER BY id_componente DESC LIMIT 1')
        .first["id_componente"]
        .to_i

      submitted_campos = params.dig(:componente, :campos_attributes) || {}

      # 3) Insertar campos (raíz) + opciones + subcampos + opciones
      submitted_campos.each do |_i, campo|
        next if campo.blank?
        next unless campo_activo?(campo) # si está incompleto, no lo insertamos

        # --- Insert campo raíz ---
        campo_row = Siac::SiacRepository.query(<<~SQL).first
          INSERT INTO "SIAC_Campos"
            (id_componente, nombre_campo, es_obligatorio, pregunta_orientadora,
            id_tipo_campo, permite_archivos, es_autovaluacion, id_campo_padre, activo)
          VALUES
            (#{id_componente},
            #{sql_quote(campo["pregunta"])},
            #{bit(campo["obligatorio"])},
            #{pregunta_orientadora_sql(campo)},
            #{campo["tipo_campo_id"].to_i},
            #{bit(campo["permite_adjuntos"])},
            #{bit(campo["autoevaluacion"])},
            NULL,
            B'1')
          RETURNING id_campo
        SQL

        id_campo_padre = campo_row["id_campo"].to_i

        # --- Opciones del campo raíz ---
        (campo["opciones_campos_attributes"] || {}).each do |_k, opt|
          nombre_opcion = opt["opcion"].to_s.strip
          next if nombre_opcion.empty?

          Siac::SiacRepository.query(<<~SQL)
            INSERT INTO "SIAC_OpcionesCampo" (id_campo, nombre_opcion, activo)
            VALUES (#{id_campo_padre}, #{sql_quote(nombre_opcion)}, B'1')
          SQL
        end

        # --- Subcampos ---
        (campo["subcampos_attributes"] || {}).each do |_j, sub|
          next if sub.blank?
          next unless campo_activo?(sub)

          sub_row = Siac::SiacRepository.query(<<~SQL).first
            INSERT INTO "SIAC_Campos"
              (id_componente, nombre_campo, es_obligatorio, pregunta_orientadora,
              id_tipo_campo, permite_archivos, es_autovaluacion, id_campo_padre, activo)
            VALUES
              (#{id_componente},
              #{sql_quote(sub["pregunta"])},
              #{bit(sub["obligatorio"])},
              #{pregunta_orientadora_sql(sub)},
              #{sub["tipo_campo_id"].to_i},
              #{bit(sub["permite_adjuntos"])},
              #{bit(sub["autoevaluacion"] || campo["autoevaluacion"])},
              #{id_campo_padre},
              B'1')
            RETURNING id_campo
          SQL

          id_subcampo = sub_row["id_campo"].to_i

          # --- Opciones del subcampo ---
          (sub["opciones_campos_attributes"] || {}).each do |_kk, opt2|
            nombre_opcion2 = opt2["opcion"].to_s.strip
            next if nombre_opcion2.empty?

            Siac::SiacRepository.query(<<~SQL)
              INSERT INTO "SIAC_OpcionesCampo" (id_campo, nombre_opcion, activo)
              VALUES (#{id_subcampo}, #{sql_quote(nombre_opcion2)}, B'1')
            SQL
          end
        end
      end
    end

    redirect_to componentes_path, notice: "Componente creada correctamente."
  rescue => e
    Rails.logger.error "❌ Error creando componente: #{e.class} - #{e.message}"
    flash.now[:error] = "Error al guardar componente: #{e.message}"

    # Re-armar el objeto para que el form vuelva a mostrar lo que cargaron
    @componente = Componente.new(componente_params)

    # Recargar selects (PG)
    load_select_options

    render :new
  end

 
  # frozen_string_literal: true
  require "ostruct"

  def preview
    id = params[:id].to_i

    # 1) Componente
    comp = Siac::SiacRepository.query(<<~SQL).first
      SELECT id_componente, id_dimension, nombre, descripcion, activo
      FROM "SIAC_Componentes"
      WHERE id_componente = #{id}
      LIMIT 1
    SQL

    raise ActiveRecord::RecordNotFound, "Componente no encontrada" unless comp

    @componente = OpenStruct.new(
      id: comp["id_componente"],
      dimension_id: comp["id_dimension"],
      nombre: comp["nombre"],
      descripcion: comp["descripcion"],
      activo: comp["activo"]
    )

    # 2) Campos raíz (sin padre)
    campos_rows = Siac::SiacRepository.query(<<~SQL)
      SELECT
        id_campo,
        id_componente,
        nombre_campo,
        es_obligatorio,
        pregunta_orientadora,
        id_tipo_campo,
        permite_archivos,
        es_autovaluacion,
        id_campo_padre,
        activo
      FROM "SIAC_Campos"
      WHERE id_componente = #{id}
        AND activo = B'1'
        AND id_campo_padre IS NULL
      ORDER BY id_campo ASC
    SQL

    campos_ids = campos_rows.map { |r| r["id_campo"].to_i }

    # 3) Subcampos (hijos)
    sub_rows = if campos_ids.any?
                Siac::SiacRepository.query(<<~SQL)
                  SELECT
                    id_campo,
                    id_componente,
                    nombre_campo,
                    es_obligatorio,
                    pregunta_orientadora,
                    id_tipo_campo,
                    permite_archivos,
                    es_autovaluacion,
                    id_campo_padre,
                    activo
                  FROM "SIAC_Campos"
                  WHERE id_componente = #{id}
                    AND activo = B'1'
                    AND id_campo_padre IN (#{campos_ids.join(",")})
                  ORDER BY id_campo_padre ASC, id_campo ASC
                SQL
              else
                []
              end

    all_campo_ids = (campos_ids + sub_rows.map { |r| r["id_campo"].to_i }).uniq

    # 4) Opciones (para campos y subcampos)
    opciones_rows = if all_campo_ids.any?
                      Siac::SiacRepository.query(<<~SQL)
                        SELECT id_opcion, id_campo, nombre_opcion, activo
                        FROM "SIAC_OpcionesCampo"
                        WHERE activo = B'1'
                          AND id_campo IN (#{all_campo_ids.join(",")})
                        ORDER BY id_campo ASC, id_opcion ASC
                      SQL
                    else
                      []
                    end

    opciones_by_campo = opciones_rows.group_by { |o| o["id_campo"].to_i }

    # 5) Tipos de campo
    tipo_ids = (campos_rows.map { |r| r["id_tipo_campo"].to_i } +
                sub_rows.map   { |r| r["id_tipo_campo"].to_i }).uniq

    tipos_rows = if tipo_ids.any?
                  Siac::SiacRepository.query(<<~SQL)
                    SELECT id_tipo, nombre, descripcion, activo
                    FROM "SIAC_TiposCampo"
                    WHERE id_tipo IN (#{tipo_ids.join(",")})
                  SQL
                else
                  []
                end

    tipos_by_id = tipos_rows.each_with_object({}) do |t, h|
      h[t["id_tipo"].to_i] = OpenStruct.new(
        id: t["id_tipo"],
        nombre: t["nombre"],
        descripcion: t["descripcion"],
        activo: t["activo"]
      )
    end

    # 6) Armado de subcampos por padre
    sub_by_padre = sub_rows.group_by { |r| r["id_campo_padre"].to_i }

    # 7) Construir campos como objetos (con subcampos y opciones)
    campos_obj = campos_rows.map do |r|
      campo_id = r["id_campo"].to_i

      sub_objs = (sub_by_padre[campo_id] || []).map do |s|
        sid = s["id_campo"].to_i
        OpenStruct.new(
          id: sid,
          nombre_campo: s["nombre_campo"],
          es_obligatorio: s["es_obligatorio"],
          pregunta_orientadora: s["pregunta_orientadora"],
          permite_archivos: s["permite_archivos"],
          es_autovaluacion: s["es_autovaluacion"],
          tipo_campo: tipos_by_id[s["id_tipo_campo"].to_i],
          opciones_campos: (opciones_by_campo[sid] || []).map { |o| OpenStruct.new(id: o["id_opcion"], nombre_opcion: o["nombre_opcion"]) }
        )
      end

      OpenStruct.new(
        id: campo_id,
        nombre_campo: r["nombre_campo"],
        es_obligatorio: r["es_obligatorio"],
        pregunta_orientadora: r["pregunta_orientadora"],
        permite_archivos: r["permite_archivos"],
        es_autovaluacion: r["es_autovaluacion"],
        tipo_campo: tipos_by_id[r["id_tipo_campo"].to_i],
        opciones_campos: (opciones_by_campo[campo_id] || []).map { |o| OpenStruct.new(id: o["id_opcion"], nombre_opcion: o["nombre_opcion"]) },
        subcampos: sub_objs
      )
    end

    # 8) Separar en convocatoria vs autoevaluación (ojo: BIT => comparar por string/valor)
    @campos_convocatoria   = campos_obj.select { |c| c.es_autovaluacion.to_s == "0" || c.es_autovaluacion == "0" }
    @campos_autoevaluacion = campos_obj.select { |c| c.es_autovaluacion.to_s == "1" || c.es_autovaluacion == "1" }

    # 9) Listas para selects (corregido namespace)
    @grupos_investigacion  = Siac::SiacRepository.query('SELECT id_grupo, denominacion FROM siac_obtener_grupos_investigacion')
    @centros_investigacion = Siac::SiacRepository.query('SELECT id_centro, denominacion FROM siac_obtener_centros_investigacion')

    render :preview
  rescue => e
    Rails.logger.error "❌ Error en preview: #{e.class} - #{e.message}"
    redirect_to componentes_path, alert: "Error cargando preview: #{e.message}"
  end




  def show
    row = Siac::SiacRepository.query(<<~SQL).first
      SELECT id_componente, id_dimension, nombre, descripcion, activo
      FROM "SIAC_Componentes"
      WHERE id_componente = #{params[:id].to_i}
      LIMIT 1
    SQL

    raise ActiveRecord::RecordNotFound unless row

    @componente = OpenStruct.new(
      id: row["id_componente"],
      dimension_id: row["id_dimension"],
      nombre: row["nombre"],
      descripcion: row["descripcion"],
      activo: row["activo"]
    )
end


  def edit
    id = params[:id].to_i

    # --- Componente ---
    comp = Siac::SiacRepository.query(<<~SQL).first
      SELECT id_componente, id_dimension, nombre, descripcion, activo
      FROM "SIAC_Componentes"
      WHERE id_componente = #{id}
      LIMIT 1
    SQL
    raise ActiveRecord::RecordNotFound unless comp

    @componente = OpenStruct.new(
      id: comp["id_componente"],
      dimension_id: comp["id_dimension"],
      nombre: comp["nombre"],
      descripcion: comp["descripcion"],
      activo: comp["activo"]
    )

    load_select_options

    # --- Campos raíz (padre NULL) ---
    campos_rows = Siac::SiacRepository.query(<<~SQL)
      SELECT
        id_campo,
        id_componente,
        nombre_campo,
        es_obligatorio,
        pregunta_orientadora,
        id_tipo_campo,
        permite_archivos,
        es_autovaluacion,
        id_campo_padre,
        activo
      FROM "SIAC_Campos"
      WHERE id_componente = #{id}
        AND activo = B'1'
        AND id_campo_padre IS NULL
      ORDER BY id_campo ASC
    SQL

    campos_ids = campos_rows.map { |r| r["id_campo"].to_i }

    # --- Subcampos ---
    sub_rows = if campos_ids.any?
                Siac::SiacRepository.query(<<~SQL)
                  SELECT
                    id_campo,
                    id_componente,
                    nombre_campo,
                    es_obligatorio,
                    pregunta_orientadora,
                    id_tipo_campo,
                    permite_archivos,
                    es_autovaluacion,
                    id_campo_padre,
                    activo
                  FROM "SIAC_Campos"
                  WHERE id_componente = #{id}
                    AND activo = B'1'
                    AND id_campo_padre IN (#{campos_ids.join(",")})
                  ORDER BY id_campo_padre ASC, id_campo ASC
                SQL
              else
                []
              end

    all_campo_ids = (campos_ids + sub_rows.map { |r| r["id_campo"].to_i }).uniq

    # --- Opciones ---
    opciones_rows = if all_campo_ids.any?
                      Siac::SiacRepository.query(<<~SQL)
                        SELECT id_opcion, id_campo, nombre_opcion, activo
                        FROM "SIAC_OpcionesCampo"
                        WHERE activo = B'1'
                          AND id_campo IN (#{all_campo_ids.join(",")})
                        ORDER BY id_campo ASC, id_opcion ASC
                      SQL
                    else
                      []
                    end

    opciones_by_campo = opciones_rows.group_by { |o| o["id_campo"].to_i }
    sub_by_padre      = sub_rows.group_by { |s| s["id_campo_padre"].to_i }

    # --- Armar estructura para el form (campos con subcampos + opciones) ---
    @componente.campos = campos_rows.map do |r|
      cid = r["id_campo"].to_i

      campo_obj = OpenStruct.new(
        id: cid,
        pregunta: r["nombre_campo"],                 # alias para tu form (pregunta)
        descripcion: r["pregunta_orientadora"],      # alias para tu form (descripcion)
        obligatorio: r["es_obligatorio"].to_s,       # BIT -> string
        permite_adjuntos: r["permite_archivos"].to_s,
        autoevaluacion: r["es_autovaluacion"].to_s,
        tipo_campo_id: r["id_tipo_campo"].to_i,
        tiene_pregunta_orientadora: r["pregunta_orientadora"].present? ? "1" : "0",
        opciones_campos: (opciones_by_campo[cid] || []).map do |o|
          OpenStruct.new(
            id: o["id_opcion"],
            opcion: o["nombre_opcion"]
          )
        end,
        subcampos: []
      )

      # Subcampos
      campo_obj.subcampos = (sub_by_padre[cid] || []).map do |s|
        sid = s["id_campo"].to_i

        sub_obj = OpenStruct.new(
          id: sid,
          pregunta: s["nombre_campo"],
          descripcion: s["pregunta_orientadora"],
          obligatorio: s["es_obligatorio"].to_s,
          permite_adjuntos: s["permite_archivos"].to_s,
          autoevaluacion: s["es_autovaluacion"].to_s,
          tipo_campo_id: s["id_tipo_campo"].to_i,
          tiene_pregunta_orientadora: s["pregunta_orientadora"].present? ? "1" : "0",
          opciones_campos: (opciones_by_campo[sid] || []).map do |o|
            OpenStruct.new(id: o["id_opcion"], opcion: o["nombre_opcion"])
          end
        )

        sub_obj
      end


      campo_obj
    end

    @componente.campos_convo    = @componente.campos.select { |c| c.autoevaluacion.to_s == "0" }
    @componente.campos_autoeval = @componente.campos.select { |c| c.autoevaluacion.to_s == "1" }

  end


  

  def update
    id_componente = params[:id].to_i
    Rails.logger.error "UPDATE NUEVO CARGADO #{Time.now}"

    # ✅ NORMALIZACIÓN (evita que autoevaluación quede “enterrada” dentro del campo 0)
    submitted_campos = normalize_campos_attributes(params.dig(:componente, :campos_attributes))

    # --- FIX: cuando el form manda el campo en un índice y las opciones en otro ---
    # Ej: {"0"=>{id:43,...}, "1"=>{opciones_campos_attributes:{...}}}
    if submitted_campos.is_a?(Hash) && submitted_campos.size > 1
      # índice que realmente representa al campo (tiene id)
      idx_principal, principal = submitted_campos.find { |_k, v| v.is_a?(Hash) && v["id"].present? }

      if idx_principal && principal.is_a?(Hash)
        huérfanos = submitted_campos.select do |k, v|
          k.to_s =~ /\A\d+\z/ &&
            k.to_s != idx_principal.to_s &&
            v.is_a?(Hash) &&
            v["id"].blank? &&
            v["opciones_campos_attributes"].present?
        end

        huérfanos.each do |k, v|
          # merge de opciones al principal
          principal["opciones_campos_attributes"] ||= {}
          principal["opciones_campos_attributes"] = principal["opciones_campos_attributes"].merge(
            deep_to_h(v["opciones_campos_attributes"]) || {}
          )

          # eliminar el índice huérfano para que no pase por el loop sin id_campo
          submitted_campos.delete(k)
        end

        submitted_campos[idx_principal] = principal
      end
    end
    # --- END FIX ---


    Rails.logger.warn "DEBUG submitted_campos keys=#{submitted_campos.keys.inspect} data=#{submitted_campos.inspect}"


    submitted_autoeval = params.dig(:componente, :campos)
    submitted_autoeval = submitted_autoeval.to_unsafe_h if submitted_autoeval.is_a?(ActionController::Parameters)

    if submitted_autoeval.is_a?(Hash) && submitted_autoeval["id"].present?
      next_index = (submitted_campos.keys.map(&:to_i).max || -1) + 1
      submitted_campos[next_index.to_s] = submitted_autoeval
    end

    # Validar existencia componente
    comp = Siac::SiacRepository.query(<<~SQL).first
      SELECT id_componente
      FROM "SIAC_Componentes"
      WHERE id_componente = #{id_componente}
      LIMIT 1
    SQL

    unless comp
      redirect_to componentes_path, alert: "Componente no encontrada."
      return
    end

    ActiveRecord::Base.transaction do
      # 1) Update componente (cabecera)
      Siac::SiacRepository.procedure(
        "SIAC_ACTUALIZAR_COMPONENTE",
        nil,
        id_componente,
        params.dig(:componente, :dimension_id).to_i,
        params.dig(:componente, :nombre).to_s,
        params.dig(:componente, :descripcion).to_s,
        "1" # BIT activo
      )

      # 2) Traer IDs existentes en BD (campos y subcampos)
      existentes = Siac::SiacRepository.query(<<~SQL)
        SELECT id_campo
        FROM "SIAC_Campos"
        WHERE id_componente = #{id_componente}
      SQL
      existentes_ids = existentes.map { |r| r["id_campo"].to_i }

      # Vamos a guardar los IDs que sí llegaron en el formulario (para no “desaparecer”)
      submitted_ids = []

      # 3) Procesar campos raíz
      submitted_campos.each do |idx, campo_data|
        next unless idx.to_s.match?(/\A\d+\z/)
        next if campo_data.blank?

        # ✅ Si el usuario lo “eliminó” desde el form, lo inactivamos y seguimos
        destroy_flag = campo_data["_destroy"].to_s
        if destroy_flag == "1" || destroy_flag.downcase == "true"
          if campo_data["id"].present?
            id_campo_del = campo_data["id"].to_i

            Siac::SiacRepository.query(<<~SQL)
              UPDATE "SIAC_Campos"
              SET activo = B'0'
              WHERE id_campo = #{id_campo_del}
            SQL

            Siac::SiacRepository.query(<<~SQL)
              UPDATE "SIAC_OpcionesCampo"
              SET activo = B'0'
              WHERE id_campo = #{id_campo_del}
            SQL
          end

          next
        end


        # --- NORMALIZAR OPCIONES (EVITA "null" Y FORMAS NO INDEXADAS) ---

        # 1) Si viene la key "null" (la genera el JS), la mezclamos y la eliminamos
        if campo_data.is_a?(Hash) && campo_data["null"].is_a?(Hash)
          null_opts = campo_data.dig("null", "opciones_campos_attributes")
          campo_data["opciones_campos_attributes"] ||= null_opts if null_opts.present?
          campo_data.delete("null")
        end

        # 2) Si opciones_campos_attributes viene como hash "suelto", envolverlo
        opts = campo_data["opciones_campos_attributes"]
        if opts.is_a?(Hash) && (opts.key?("id") || opts.key?("opcion") || opts.key?("valor") || opts.key?("_destroy"))
          already_indexed = opts.keys.all? { |k| k.to_s =~ /\A\d+\z/ }
          campo_data["opciones_campos_attributes"] = already_indexed ? opts : { "0" => opts }
        end

        # --- Determinar “activa” según tus reglas ---
        activa = campo_activo?(campo_data)

        # --- Insert / update campo raíz ---
        id_campo = campo_data["id"].present? ? campo_data["id"].to_i : nil

        if id_campo
          submitted_ids << id_campo

          po_val = pregunta_orientadora_value(campo_data) # ✅ nil o string (NO "NULL")

          Siac::SiacRepository.query(<<~SQL)
            CALL siac_actualizar_campos(
              NULL::integer,
              #{id_campo}::integer,
              #{sql_quote(campo_data["pregunta"].to_s)}::text,
              #{bit(campo_data["obligatorio"])}::bit,
              #{po_val.nil? ? "NULL::text" : "#{sql_quote(po_val)}::text"},
              #{campo_data["tipo_campo_id"].to_i}::integer,
              #{bit(campo_data["permite_adjuntos"])}::bit,
              #{bit(campo_data["autoevaluacion"])}::bit
            );
          SQL

          # Activar / inactivar
          Siac::SiacRepository.query(<<~SQL)
            UPDATE "SIAC_Campos"
            SET activo = #{activa ? "B'1'" : "B'0'"}
            WHERE id_campo = #{id_campo}
          SQL
        else
          # Insertar solo si está “activa”
          if activa
            po_val = pregunta_orientadora_value(campo_data) # ✅ nil o string

            row = Siac::SiacRepository.query(<<~SQL).first
              INSERT INTO "SIAC_Campos"
                (id_componente, nombre_campo, es_obligatorio, pregunta_orientadora,
                id_tipo_campo, permite_archivos, es_autovaluacion, id_campo_padre, activo)
              VALUES
                (#{id_componente},
                #{sql_quote(campo_data["pregunta"])},
                #{bit(campo_data["obligatorio"])},
                #{po_val.nil? ? "NULL" : sql_quote(po_val)},
                #{campo_data["tipo_campo_id"].to_i},
                #{bit(campo_data["permite_adjuntos"])},
                #{bit(campo_data["autoevaluacion"])},
                NULL,
                B'1')
              RETURNING id_campo
            SQL

            id_campo = row["id_campo"].to_i
            submitted_ids << id_campo
          end
        end

        # 4) Opciones del campo raíz
        if id_campo
          opciones = campo_data["opciones_campos_attributes"] ||
                    campo_data.dig("null", "opciones_campos_attributes")
          upsert_opciones(id_campo, opciones)
        end

        # 5) Subcampos
        
        # --- NORMALIZAR SUBCAMPOS (si llegan como "subcampos" en vez de "subcampos_attributes") ---
        if campo_data.is_a?(Hash) && campo_data["subcampos"].present? && campo_data["subcampos_attributes"].blank?
          campo_data["subcampos_attributes"] = deep_to_h(campo_data["subcampos"])
          campo_data.delete("subcampos")
        end

        # --- NORMALIZAR SUBCAMPOS (si vienen como hash suelto, reemplazar por hash indexado) ---
        subs = campo_data["subcampos_attributes"]
        subs = deep_to_h(subs)

        if subs.is_a?(Hash)
          only_numeric = subs.keys.all? { |k| k.to_s =~ /\A\d+\z/ }

          unless only_numeric
            looks_like_sub = subs.key?("id") || subs.key?("pregunta") || subs.key?("tipo_campo_id") || subs.key?("_destroy")

            if looks_like_sub
              # 🔥 IMPORTANTE: reemplazar (no merge), para no dejar keys "id/pregunta" arriba
              campo_data["subcampos_attributes"] = { "0" => subs }
            end
          end
        end

        Rails.logger.warn("AFTER sub wrap: #{campo_data["subcampos_attributes"].inspect}")



        (campo_data["subcampos_attributes"] || {}).each do |_j, sub_data|
          next if sub_data.blank?

          sub_activa = campo_activo?(sub_data)
          id_sub = sub_data["id"].present? ? sub_data["id"].to_i : nil

          if id_sub
            submitted_ids << id_sub

            po_sub_val = pregunta_orientadora_value(sub_data)

            Siac::SiacRepository.query(<<~SQL)
              CALL siac_actualizar_campos(
                NULL::integer,
                #{id_sub}::integer,
                #{sql_quote(sub_data["pregunta"].to_s)}::text,
                #{bit(sub_data["obligatorio"])}::bit,
                #{po_sub_val.nil? ? "NULL::text" : "#{sql_quote(po_sub_val)}::text"},
                #{sub_data["tipo_campo_id"].to_i}::integer,
                #{bit(sub_data["permite_adjuntos"])}::bit,
                #{bit(sub_data["autoevaluacion"] || campo_data["autoevaluacion"])}::bit
              );
            SQL

            Siac::SiacRepository.query(<<~SQL)
              UPDATE "SIAC_Campos"
              SET activo = #{sub_activa ? "B'1'" : "B'0'"}
              WHERE id_campo = #{id_sub}
            SQL
          else
            if sub_activa
              po_sub_val = pregunta_orientadora_value(sub_data)

              row = Siac::SiacRepository.query(<<~SQL).first
                INSERT INTO "SIAC_Campos"
                  (id_componente, nombre_campo, es_obligatorio, pregunta_orientadora,
                  id_tipo_campo, permite_archivos, es_autovaluacion, id_campo_padre, activo)
                VALUES
                  (#{id_componente},
                  #{sql_quote(sub_data["pregunta"])},
                  #{bit(sub_data["obligatorio"])},
                  #{po_sub_val.nil? ? "NULL" : sql_quote(po_sub_val)},
                  #{sub_data["tipo_campo_id"].to_i},
                  #{bit(sub_data["permite_adjuntos"])},
                  #{bit(sub_data["autoevaluacion"] || campo_data["autoevaluacion"])},
                  #{id_campo},
                  B'1')
                RETURNING id_campo
              SQL

              id_sub = row["id_campo"].to_i
              submitted_ids << id_sub
            end
          end

          # --- NORMALIZAR OPCIONES EN SUBCAMPO (null + suelto) ---
          if sub_data.is_a?(Hash) && sub_data["null"].is_a?(Hash)
            null_opts = sub_data.dig("null", "opciones_campos_attributes")
            sub_data["opciones_campos_attributes"] ||= null_opts if null_opts.present?
            sub_data.delete("null")
          end

          opts2 = sub_data["opciones_campos_attributes"]
          if opts2.is_a?(Hash) && (opts2.key?("id") || opts2.key?("opcion") || opts2.key?("valor") || opts2.key?("_destroy"))
            already_indexed2 = opts2.keys.all? { |k| k.to_s =~ /\A\d+\z/ }
            sub_data["opciones_campos_attributes"] = already_indexed2 ? opts2 : { "0" => opts2 }
          end


          # Opciones del subcampo
          if id_sub
            opciones = sub_data["opciones_campos_attributes"] ||
                      sub_data.dig("null", "opciones_campos_attributes")
            upsert_opciones(id_sub, opciones)
          end
        end
      end

      # (opcional) log para verificar que NO se “pierde” autoevaluación
      Rails.logger.warn "existentes_ids=#{existentes_ids.sort} submitted_ids=#{submitted_ids.compact.uniq.sort}"

      
    end

    redirect_to componentes_path, notice: "Componente actualizada."
  rescue => e
    Rails.logger.error "❌ Error actualizando componente: #{e.class} - #{e.message}"
    load_select_options
    redirect_to edit_componente_path(params[:id]), alert: "Error al actualizar: #{e.message}"
  end


  

  def destroy
      Siac::SiacRepository.procedure(
        "SIAC_BORRAR_COMPONENTE",
        params[:id].to_i
      )

      redirect_to componentes_path, notice: 'Componente marcada como inactiva.'
    rescue => e
      Rails.logger.error "❌ Error borrando componente: #{e.message}"
      redirect_to componentes_path, alert: 'Error al eliminar componente.'
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

    def bit(val)
      v = val.to_s
      (v == "1" || v.downcase == "true") ? "B'1'" : "B'0'"
    end

    def deep_to_h(obj)
      case obj
      when ActionController::Parameters
        obj.to_unsafe_h.transform_values { |v| deep_to_h(v) }
      when Hash
        obj.transform_values { |v| deep_to_h(v) }
      else
        obj
      end
    end

    def normalize_campos_attributes(raw)
      h = deep_to_h(raw)
      return {} if h.blank?

      # Si ya viene indexado puro: {"0"=>{...}, "1"=>{...}}
      return h if h.is_a?(Hash) && h.keys.all? { |k| k.to_s =~ /\A\d+\z/ }

      indexed = {}
      loose   = {}

      h.each do |k, v|
        if k.to_s =~ /\A\d+\z/
          indexed[k.to_s] = v
        else
          loose[k.to_s] = v
        end
      end

      # ✅ Si viene un "campo raíz" suelto (id/pregunta/etc), lo metemos dentro de un índice
      if loose.present?
        target_key = loose["id"].present? ? loose["id"].to_s : "0"

        if indexed.key?(target_key) && indexed[target_key].is_a?(Hash)
          indexed[target_key] = loose.merge(indexed[target_key])
        else
          indexed[target_key] = loose
        end
      end


      indexed
      
    end






    def campo_activo?(data)
      return false if data.blank?
      pregunta = data["pregunta"].to_s.strip
      tipo     = data["tipo_campo_id"].to_s.strip

      return false if pregunta.empty? || tipo.empty?

      # si tiene_pregunta_orientadora == "1", exige descripcion no vacía
      if data["tiene_pregunta_orientadora"].to_s == "1"
        return false if data["descripcion"].to_s.strip.empty?
      end

      true
    end

    def pregunta_orientadora_value(data)
      tiene = data["tiene_pregunta_orientadora"].to_s == "1"
      desc  = data["descripcion"].to_s.strip
      return nil unless tiene && desc.present?
      desc
    end
    



    def sql_quote(str)
      ActiveRecord::Base.connection.quote(str.to_s)
    end
      
    def upsert_opciones(id_campo, opciones_hash)
      opciones = deep_to_h(opciones_hash) || {}

      # si viene suelto, envolver
      if opciones.is_a?(Hash) && (opciones.key?("id") || opciones.key?("opcion") || opciones.key?("valor") || opciones.key?("_destroy"))
        already_indexed = opciones.keys.all? { |k| k.to_s =~ /\A\d+\z/ }
        opciones = already_indexed ? opciones : { "0" => opciones }
      end

      opciones.each do |_k, opt|
        opt ||= {}

        destroy_flag = opt["_destroy"].to_s
        if destroy_flag == "1" || destroy_flag.downcase == "true"
          if opt["id"].present?
            Siac::SiacRepository.procedure("SIAC_MODIFICAR_OPCIONES_CAMPO", nil, opt["id"].to_i, opt["opcion"].to_s.strip, "0")
          end
          next
        end

        nombre = opt["opcion"].to_s.strip
        if nombre.empty?
          if opt["id"].present?
            Siac::SiacRepository.procedure("SIAC_MODIFICAR_OPCIONES_CAMPO", nil, opt["id"].to_i, "", "0")
          end
          next
        end

        if opt["id"].present?
          Siac::SiacRepository.procedure("SIAC_MODIFICAR_OPCIONES_CAMPO", nil, opt["id"].to_i, nombre, "1")
        else
          Siac::SiacRepository.query(<<~SQL)
            INSERT INTO "SIAC_OpcionesCampo" (id_campo, nombre_opcion, activo)
            VALUES (#{id_campo}, #{sql_quote(nombre)}, B'1')
          SQL
        end
      end
    end



    def load_select_options
      @dimensiones = fetch_dimensiones_convo
      @tipos_campo = fetch_tipos_campo
    end

    def fetch_dimensiones_convo
      rows = Siac::SiacRepository.query(<<~SQL)
        SELECT id_dimension, nombre, descripcion, activo
        FROM siac_obtener_dimensiones_convo
        WHERE activo = B'1'
        ORDER BY id_dimension ASC
      SQL

      rows.map do |r|
        OpenStruct.new(
          id: r["id_dimension"],
          dimension: r["nombre"] # tu select usa :dimension como texto
        )
      end
    end

    def pregunta_orientadora_sql(data)
      val = pregunta_orientadora_value(data) # => nil o string
      val.nil? ? "NULL" : sql_quote(val)     # => "NULL" o "'texto'"
    end

    def fetch_tipos_campo
      rows = Siac::SiacRepository.query(<<~SQL)
        SELECT id_tipo, nombre, descripcion, activo
        FROM siac_obtener_tipos_campo
        WHERE activo = B'1'
        ORDER BY id_tipo ASC
      SQL

      rows.map do |r|
        OpenStruct.new(
          id: r["id_tipo"],
          nombre: r["nombre"]
        )
      end
    end


end
