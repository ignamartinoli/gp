module ComponenteHelper

  ##############################################
  # FUNCIÓN PRINCIPAL → Genera todo el bloque
  ##############################################
  def generar_campo(campo, numero = nil)
    content_tag(:div, class: 'campo-contenedor p-3 mb-3 border rounded bg-light') do
      # 1️⃣ Título o pregunta principal con numeración
      titulo = numero.present? ? "#{numero}. #{campo.pregunta}" : campo.pregunta
      html = content_tag(:h2, titulo, class: 'campo-pregunta h6 fw-bold mb-2')

      # 2️⃣ Pregunta orientadora (si aplica)
      html << render_pregunta_orientadora(campo)

      # 3️⃣ Input según tipo de campo
      html << render_field_for(campo)

      # 4️⃣ Input para adjunto (si aplica)
      html << render_attachment_if_allowed(campo)

      html.html_safe
    end
  end



  ##############################################
  # FUNCIÓN DE ENRUTAMIENTO → Llama al tipo
  ##############################################
  def render_field_for(campo)
    # Detectar si es un subcampo
    if campo.is_a?(Subcampo)
      return render_field_for_subcampo(campo)
    end

    # Si es Campo normal
    tipo = campo.tipo_campo.try(:nombre)&.downcase

    case tipo
    when /texto/
      render_text_field(campo)
    when /seleccion multiple/
      render_multiple_select(campo)
    when /seleccion unica/
      render_single_select(campo)
    when /fecha/
      render_date_field(campo)
    when /numero/
      render_number_field(campo)
    when /barra de progreso/
      render_progress_bar(campo)
    when /plantel docente/
      render_plantel_docente(campo)
    else
      render_generic_field(campo)
    end
  end

  def render_field_for_subcampo(sub)
    case sub.tipo_campo_id.to_i
    when 7
      render_text_field(sub)
    when 8 # Selección Única
      render_single_select(sub)
    when 9 # Selección Múltiple
      render_multiple_select(sub)
    when 10 # Fecha
      render_date_field(sub)
    when 11 # Número
      render_number_field(sub)
    else
      render_generic_field(sub)
    end
  end



  ##############################################
  # FUNCIONES DE RENDERIZADO POR TIPO
  ##############################################

  # Campo de texto
  def render_text_field(campo)
    content_tag(:div, class: 'campo-texto') do
      text_area_tag("campo_#{campo.id}", nil,
        class: 'tipo-campo-texto form-control',
        maxlength: 2000,
        rows: 3,
        placeholder: 'Escribí tu respuesta...')
    end
  end

  # Selección múltiple → Checkboxes
  def render_multiple_select(campo)
    content_tag(:div, class: 'tipo-campo-multiple') do
      campo.opciones_campos.map do |opt|
        content_tag(:label, class: 'tipo-campo-multiple-op form-check-label d-block') do
          check_box_tag("campo_#{campo.id}[]", opt.valor, false, class: 'form-check-input me-2') +
          opt.opcion
        end
      end.join.html_safe
    end
  end

  # Selección única → Lista desplegable
  def render_single_select(campo)
    content_tag(:div, class: 'tipo-campo-unica') do
      select_tag("campo_#{campo.id}",
                 options_from_collection_for_select(campo.opciones_campos, 'valor', 'opcion'),
                 include_blank: 'Seleccione una opción',
                 class: 'tipo-campo-select form-select')
    end
  end

  # Campo fecha
  def render_date_field(campo)
    content_tag(:div, class: 'campo-fecha') do
      date_field_tag("campo_#{campo.id}", nil, class: 'form-control')
    end
  end

  # Campo número
  def render_number_field(campo)
    content_tag(:div, class: 'campo-numero') do
      number_field_tag("campo_#{campo.id}", nil, class: 'form-control', step: 'any', placeholder: 'Ingrese un valor numérico')
    end
  end

  # Barra de progreso
  # Barra de progreso con descripción
  def render_progress_bar(campo)
    content_tag(:div, class: 'campo-progreso w-100') do

      # Contenedor horizontal slider + porcentaje
      fila_slider = content_tag(:div, class: 'slider-wrapper d-flex align-items-center w-100') do
        tag.input(
          type: 'range',
          min: 0,
          max: 100,
          value: 50,
          class: 'tipo-campo-barra form-range flex-grow-1',
          id: "slider_#{campo.id}",
          oninput: "document.getElementById('valor_progreso_#{campo.id}').innerText = this.value + '%';"
        ) +
        content_tag(:div, "50%", class: 'tipo-campo-barra-label fw-bold ms-2', id: "valor_progreso_#{campo.id}")
      end

      # Textarea debajo
      descripcion = content_tag(:div, class: 'campo-texto mt-2 w-100') do
        text_area_tag("campo_#{campo.id}_desc", nil,
          class: 'form-control tipo-campo-texto',
          rows: 2,
          maxlength: 500,
          placeholder: "Descripción de la valoración..."
        )
      end

      fila_slider + descripcion
    end
  end

  def render_plantel_docente(campo)
    content_tag(:div, class: 'campo-plantel-docente') do
      tabla = content_tag(:table, class: 'table table-bordered table-sm custom-table') do
        thead = content_tag(:thead) do
          content_tag(:tr) do
            content_tag(:th, 'Nivel') +
            content_tag(:th, 'Número') +
            content_tag(:th, 'Materia') +
            content_tag(:th, 'Se Dicta') +
            content_tag(:th, 'Docentes')
          end
        end

        tbody = content_tag(:tbody) do
          materias_para_plantel.each do |fila|
            concat render_fila_plantel(
              campo,
              fila[:nivel],
              fila[:numero],
              fila[:materia]
            )
          end

          if defined?(@materias) && @materias.respond_to?(:current_page)
            concat(
              content_tag(:tr, class: 'paginationTr') do
                content_tag(:td, colspan: 4) do
                  content_tag(
                    :div,
                    paginate(@materias, params: request.query_parameters,remote: false),
                    class: 'pagination_menu'
                  )
                end
              end
            )
          end
        end


        thead + tbody
      end

      tabla + render_modal_docente(campo)
    end
  end



  def render_fila_plantel(campo, nivel, numero, materia)
    content_tag(:tr) do
      content_tag(:td, nivel || '-') +
      content_tag(:td, numero || '-') +
      content_tag(:td, materia) +
      content_tag(:td) do
        check_box_tag(
          'materias[][se_dicta]',  # nombre (ajustable)
          '1',                     # value
          true                     # ✔ marcado por defecto
        )
      end + 
      content_tag(:td) do
        content_tag(:div, class: 'docentes-container', data: { materia: materia }) do
          content_tag(:div, 'Sin docentes cargados', class: 'docentes-empty') +
          render_boton_agregar_docente(campo, materia)
        end
      end
    end
  end



  def render_modal_docente(campo)
    content_tag(:div,
      id: "modal_docente_#{campo.id}",
      title: 'Carga de Docente',   # 👈 CLAVE
      style: 'display:none;'
    ) do
      render_modal_docente_contenido(campo)
    end
  end

  def materias_para_plantel
    filas = if defined?(@materias) && @materias.any?
      @materias
    else
      materias_mockeadas
    end

    filas.map do |m|
      codigo = m['codigo_materia'] || m[:codigo_materia]
      nombre = m['nombre']         || m[:nombre]

      parsed = parse_codigo_materia(codigo)

      {
        nivel:   parsed[:nivel],
        numero:  parsed[:numero],
        materia: nombre
      }
    end
  end



  def materias_mockeadas
    [
      { codigo_materia: '5-2023-101', nombre: 'Didáctica General' },
      { codigo_materia: '5-2023-202', nombre: 'Práctica Docente I' }
    ]
  end




  def render_modal_docente_contenido(campo)
    render_stepper +
    render_step_identificacion +
    render_step_datos_personales +
    render_step_desempeno_academico +   # 👈 NUEVO
    render_step_investigacion +
    render_step_datos_laborales +
    render_step_footer
  end


  def render_busqueda_cuit
    content_tag(:fieldset, class: 'box') do
      content_tag(:legend, 'Buscar docente por CUIT') +
      content_tag(:div, class: 'd-flex gap-2') do
        text_field_tag(
          'docente[cuit]',
          nil,
          class: 'form-control',
          placeholder: 'CUIT del docente',
          data: {
            step: 'identificacion',
            path: 'docente.cuit',
            required: true,
            type: 'cuit'
          }
        ) +
        button_tag('Buscar',
          type: 'button',
          class: 'btn btn-primary siac_button_secondary'
        )
      end +
      content_tag(:div,
        'Docente no encontrado',
        class: 'alert alert-warning mt-2',
        style: 'display:none;',
        id: 'docente-no-encontrado'
      )
    end
  end

  def render_datos_personales
    content_tag(:div, class: 'step-content', data: { step: 'datos_personales' }) do
      content_tag(:fieldset, class: 'box datos-personales-step') do
        content_tag(:legend, 'Datos personales') +

        # 🔹 Nombre
        content_tag(:div, class: 'mb-3') do
          label_tag('docente_nombre', 'Nombre', class: 'form-label fw-bold') +
          text_field_tag(
            'docente[nombre]',
            nil,
            id: 'docente_nombre',
            class: 'form-control',
            placeholder: 'Nombre',
            data: {
              step: 'datos_personales',
              path: 'docente.nombre',
              required: true
            }
          )
        end +

        # 🔹 Apellido
        content_tag(:div, class: 'mb-3') do
          label_tag('docente_apellido', 'Apellido', class: 'form-label fw-bold') +
          text_field_tag(
            'docente[apellido]',
            nil,
            id: 'docente_apellido',
            class: 'form-control',
            placeholder: 'Apellido',
            data: {
              step: 'datos_personales',
              path: 'docente.apellido',
              required: true
            }
          )
        end +

        # 🔹 Fecha de nacimiento (ACLARADO)
        content_tag(:div, class: 'mb-3') do
          label_tag(
            'docente_fecha_nacimiento',
            'Fecha de nacimiento',
            class: 'form-label fw-bold'
          ) +
          date_field_tag(
            'docente[fecha_nacimiento]',
            nil,
            id: 'docente_fecha_nacimiento',
            class: 'form-control',
            data: {
              step: 'datos_personales',
              path: 'docente.fecha_nacimiento',
              required: true,
              type: 'date'
            }
          ) 
        end +

        # 🔹 Titulación
        content_tag(:div, class: 'mb-3') do
          label_tag(
            'docente_titulacion',
            'Titulación',
            class: 'form-label fw-bold'
          ) +
          select_tag(
            'docente[titulacion]',
            options_for_select([
              ['Seleccione titulación', ''],
              ['Ingeniero/a', 'ingeniero'],
              ['Licenciado/a', 'licenciado'],
              ['Doctor/a', 'doctor'],
              ['Maestro/a', 'maestro'],
              ['Técnico/a', 'tecnico'],
              ['Otro', 'otro']
            ]),
            id: 'docente_titulacion',
            class: 'form-select',
            data: {
              step: 'datos_personales',
              path: 'docente.titulacion',
              required: true
            }
          )
        end +

        # 🔹 CV
        content_tag(:div, class: 'mb-2') do
          label_tag(
            'docente_cv',
            'Adjunte CV actualizado (solo PDF)',
            class: 'form-label fw-bold'
          ) +
          file_field_tag(
            'docente[cv]',
            id: 'docente_cv',
            class: 'form-control',
            accept: 'application/pdf',
            data: {
              step: 'datos_personales',
              path: 'docente.cv',
              required: true,
              type: 'file',
              accept: 'pdf'
            }
          )
        end
      end
    end
  end



  def render_step_desempeno_academico
    cargos_docentes = Siac::DocentesRepository.cargos_docentes_catalogo

    content_tag(:div, class: 'step-content') do
      content_tag(:fieldset, class: 'box') do
        content_tag(:legend, 'Desempeño académico') +

        content_tag(:div, class: 'desempeno-grid') do

          # 🧑‍🏫 Cargo docente
          select_tag(
            'docente[id_cargo_docente]',
            options_for_select(
              [['Seleccione cargo docente', '']] +
              Siac::DocentesRepository.cargos_docentes_catalogo.map do |c|
                [c['nombre'], c['id_cargo']]
              end
            ),
            class: 'form-select',
            data: {
              step: 'desempeno',
              path: 'desempeno.cargo_docente_id',
              required: true
            }
          ) +

          # ⏱ Horas que dicta
          number_field_tag(
            'docente[horas_dictado]',
            nil,
            min: 1,
            class: 'form-control',
            placeholder: 'Horas semanales de dictado',
            data: {
              step: 'desempeno',
              path: 'desempeno.horas_dictadas',
              required: true,
              type: 'number',
              min: 1
            }
          ) +

          # 🏫 Comisión (por ahora vacío)
          select_tag(
            'docente[id_comision]',
            options_for_select([
              ['Seleccione comisión', '']
            ]),
            class: 'form-select'
          )

        end
      end
    end
  end

  def render_datos_investigacion(grupos: [], centros: [])
    content_tag(:fieldset, class: 'box mt-3', id: 'investigacion-step',
                data: {
                  grupos: grupos.to_json,
                  centros: centros.to_json
                }) do

      content_tag(:legend, 'Investigación') +

      content_tag(:div, class: 'proyectos-container') do
        render_proyecto_investigacion(0)
      end +

      content_tag(
        :button,
        '+ Agregar otro proyecto',
        type: 'button',
        class: 'btn btn-secondary mt-3 siac_button_secondary',
        id: 'agregar-proyecto-investigacion'
      )
    end
  end

  def render_proyecto_investigacion(index)
    cargos_investigacion = Siac::DocentesRepository.cargos_investigacion_catalogo

    content_tag(:div, class: 'proyecto-investigacion mb-3', data: { index: index }) do

      text_field_tag(
        "docente[proyectos][#{index}][nombre]",
        nil,
        class: 'form-control mb-2 investigacion_nombre',
        placeholder: 'Nombre del proyecto de investigación'
      ) +

      # 🆕 CARGO INVESTIGACIÓN
      select_tag(
        "docente[proyectos][#{index}][id_cargo_investigacion]",
        options_for_select(
          [['Seleccione cargo de investigación', '']] +
          cargos_investigacion.map { |c| [c['nombre'], c['id_cargo']] }
        ),
        class: 'form-select mb-2'
      ) +

      select_tag(
        "docente[proyectos][#{index}][tipo_encuadre]",
        options_for_select([
          ['Seleccione tipo', ''],
          ['Grupo de investigación', 'grupo'],
          ['Centro de investigación', 'centro']
        ]),
        class: 'form-select mb-2 tipo-encuadre-select'
      ) +

      select_tag(
        "docente[proyectos][#{index}][referencia_id]",
        options_for_select([['Seleccione grupo o centro', '']]),
        class: 'form-select mb-2 grupo-centro-select'
      ) +

      select_tag(
        "docente[proyectos][#{index}][linea_accion]",
        options_for_select([
          ['Seleccione línea', ''],
          ['Alimentos', 1],
          ['Análisis de Señales, Modelados y Simulación', 2],
          ['Aplicaciones Mecánicas y Mecatrónica', 3],
          ['Electrónica, Computación y Comunicaciones', 4],
          ['Estructura y construcciones civiles', 5],
          ['Ingeniería Clínica y Bioingeniería', 6],
          ['Ingeniería de Procesos, Biotecnología y Tecnología de Alimentos', 7],
          ['Materiales', 8],
          ['Medio Ambiente, Contingencias y Desarrollo Sustentable', 9],
          ['Procesos y productos', 10],
          ['Sistemas de Información e Informática', 11],
          ['Tecnología Educativa y de Enseñanza de la Ingeniería', 12],
          ['Tecnologías organizacionales', 13],
          ['Transporte y Vías de la Comunicación', 14]
        ]),
        class: 'form-select mb-2'
      ) +

      number_field_tag(
        "docente[proyectos][#{index}][horas_semanales]",
        nil,
        min: 1,
        class: 'form-control',
        placeholder: 'Horas semanales dedicadas'
      )
    end
  end

  def render_datos_laborales
    content_tag(:fieldset, class: 'box mt-3 datos-laborales-step') do
      content_tag(:legend, 'Datos laborales') +

      content_tag(:div, class: 'empresa-row') do
        text_field_tag(
          'empresa[cuit]',
          nil,
          class: 'form-control empresa-cuit',
          placeholder: 'CUIT de la empresa'
        ) +

        button_tag(
          'Consultar empresa',
          type: 'button',
          class: 'btn btn-outline-secondary siac_button_secondary consultar-empresa-btn'
        )
      end +

      content_tag(
        :div,
        '—',
        id: 'empresa_nombre',
        class: 'empresa-razon-social'
      )
    end
  end


  def render_modal_footer
    content_tag(:div, class: 'mt-3 text-end') do
      button_tag('Cancelar', type: 'button', class: 'btn btn-secondary siac_button', onclick: 'hideModal(this);') +
      button_tag('Agregar docente', type: 'button', class: 'btn btn-primary ms-2 siac_button')
    end
  end

  

  def render_boton_agregar_docente(campo, materia)
    link_to 'Agregar docente',
            '#',
            class: 'btn-agregar-docente',
            data: { materia: materia },
            onclick: "openDocenteDialog('modal_docente_#{campo.id}'); return false;"  
  end


  def render_stepper
    content_tag(:div, class: 'stepper') do
      %w[
        Identificación
        Datos\ personales
        Desempeño\ académico
        Investigación
        Datos\ laborales
      ].map.with_index do |label, i|
        content_tag(:div, label, class: "step #{i == 0 ? 'active' : ''}")
      end.join.html_safe
    end
  end

  def render_step_identificacion
    content_tag(:div, class: 'step-content active') do
      render_busqueda_cuit
    end
  end

  def render_step_datos_personales
    render_datos_personales
  end

  def render_step_investigacion
    content_tag(:div, class: 'step-content') do
      render_datos_investigacion(
        grupos:  @grupos_investigacion || [],
        centros: @centros_investigacion || []
      )
    end
  end


  def render_step_datos_laborales
    content_tag(:div, class: 'step-content') do
      render_datos_laborales
    end
  end

  def render_step_footer
    content_tag(:div, class: 'step-buttons') do
      button_tag('Anterior', type: 'button', class: 'step-btn prev') +
      button_tag('Siguiente', type: 'button', class: 'step-btn next')
    end
  end

  def parse_codigo_materia(codigo)
    return { nivel: nil, numero: nil } if codigo.blank?

    parte = codigo.to_s.split('-')[2]
    return { nivel: nil, numero: nil } if parte.blank?

    nivel  = parte[0]
    numero = parte.length > 1 ? parte[1..-1] : nil

    { nivel: nivel, numero: numero }
  end



  # Fallback genérico
  def render_generic_field(campo)
    text_field_tag("campo_#{campo.id}", nil, class: 'form-control', placeholder: 'Campo genérico')
  end


  ##############################################
  # FUNCIONES COMUNES
  ##############################################

  def etapa(pdf, titulo, texto)
    pdf.text titulo, style: :bold, size: 11
    pdf.move_down 4
    pdf.text texto, size: 11, align: :justify, leading: 3
    pdf.move_down 10
  end


  def render_pregunta_orientadora(campo)
    return unless campo.respond_to?(:tiene_pregunta_orientadora)
    return unless campo.tiene_pregunta_orientadora && campo.descripcion.present?

    content_tag(:div, campo.descripcion, class: 'campo-orientadora alert alert-info mt-2 p-2 small')
  end

  def render_attachment_if_allowed(campo)
    return unless campo.respond_to?(:permite_adjuntos)
    return unless campo.permite_adjuntos

    content_tag(:div, class: 'campo-adjunto mt-2') do
      label_tag("adjunto_#{campo.id}", "Adjuntar archivo:", class: 'form-label') +
      file_field_tag("adjunto_#{campo.id}", class: 'campo-adjunto form-control-file')
    end
  end

  def get_nombre_dimension(num)
    case num.to_i
    when 1 then "Curricular"
    when 2 then "Actividad Docente"
    when 4 then "Organizacional"
    when 5 then 'Actividad del Estudiantado'
    when 6 then 'Desarrollo Academico'
    else "-"
    end
  end
end
