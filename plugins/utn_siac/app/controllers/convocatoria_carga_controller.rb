class ConvocatoriaCargaController < ApplicationController
  include Siac::ControllerGuard

  before_action :deny_siac_cliente!
  before_action :require_regional_context, only: [:edit_datos_regional, :show_datos_regional]
  
  helper ComponenteHelper
  include ConvocatoriaHelper
  
  def edit_datos_regional
    @modo = :edicion
    load_preview_data(params[:id].to_i)
    render 'convocatoria/preview'
  end

  def show_datos_regional
    @modo = :solo_lectura
    load_preview_data(params[:id].to_i)
    render 'convocatoria/preview'
  end

  private

  def load_preview_data(id)
    # 1) Convocatoria
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

    # 4) Campos asociados a la convocatoria
    campos_rows = Siac::SiacRepository.query(
      Siac::SiacRepository.send(:sanitize_sql_array, [%Q{
        SELECT * FROM SIAC_BUSCAR_CAMPOS_CONVOCATORIAS(?)
      }, id])
    )

    # 5) Tipos de campo
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

    # 6) Opciones por campo
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

    # 7) Armar estructura
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

  def require_regional_context
    regional_id = params[:regional_id].to_i
    conv_id = params[:id].to_i
    
    unless params[:regional_id].present? && regional_id > 0
      flash[:error] = "Contexto inválido. Debe seleccionar una Facultad Regional válida desde la vista de convocatoria."
      return redirect_to convocatorias_path
    end
    
    regional_row = Siac::SiacRepository.query(
      Siac::SiacRepository.send(:sanitize_sql_array, ['SELECT id_facultad, nombre FROM public."SPYP_Regionales" WHERE id_facultad = ? LIMIT 1', regional_id])
    ).first

    unless regional_row.present?
      flash[:error] = "Contexto inválido. Debe seleccionar una Facultad Regional válida."
      return redirect_to convocatorias_path
    end
    
    @regional = OpenStruct.new(id: regional_row["id_facultad"], nombre: regional_row["nombre"])

    pertenece = Siac::SiacRepository.select_value(
      Siac::SiacRepository.send(
        :sanitize_sql_array, 
        ['SELECT 1 FROM public."SIAC_ConvocatoriasXRegionales" WHERE id_convocatoria = ? AND id_facultad = ? LIMIT 1', conv_id, regional_id]
      )
    ).to_i == 1
    
    unless pertenece
      flash[:error] = "La Facultad Regional seleccionada no forma parte de esta convocatoria."
      return redirect_to convocatorias_path
    end
  end
end
