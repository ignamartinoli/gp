# app/helpers/componente_helper.rb
module ComponenteHelper

  ##############################################
  # FUNCIÓN PRINCIPAL → Genera todo el bloque
  ##############################################
  def generar_campo(campo, numero = nil)
    content_tag(:div, class: 'campo-contenedor p-3 mb-3 border rounded bg-light') do
      titulo_texto = titulo_campo(campo)
      titulo_final = numero.present? ? "#{numero}. #{titulo_texto}" : titulo_texto

      html = content_tag(:h2, titulo_final.to_s, class: 'campo-pregunta h6 fw-bold mb-2')
      html << render_pregunta_orientadora(campo)
      html << render_field_for(campo)
      html << render_attachment_if_allowed(campo)

      # IMPORTANTE:
      # NO renderizamos subcampos aquí.
      # Tu partial _formulario_preview ya hace la recursión.
      html.html_safe
    end
  end

  def titulo_campo(campo)
    campo.try(:pregunta_nombre).presence ||
      campo.try(:pregunta).presence ||
      campo.try(:nombre_campo).presence ||
      campo.try(:nombre).presence ||
      "-"
  end

  ##############################################
  # FUNCIÓN DE ENRUTAMIENTO → Llama al tipo
  ##############################################
  def render_field_for(campo)
    tipo = campo.try(:tipo_campo).try(:nombre).to_s.downcase

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

  ##############################################
  # FUNCIONES DE RENDERIZADO POR TIPO
  ##############################################

  # Campo de texto
  def render_text_field(campo)
    content_tag(:div, class: 'campo-texto') do
      text_area_tag(
        "campo_#{campo.id}",
        nil,
        class: 'tipo-campo-texto form-control',
        maxlength: 2000,
        rows: 3,
        placeholder: 'Escribí tu respuesta...'
      )
    end
  end

  # Selección múltiple → Checkboxes
  def render_multiple_select(campo)
    opciones = normalize_opciones(campo)

    content_tag(:div, class: 'tipo-campo-multiple') do
      opciones.map do |opt|
        content_tag(:label, class: 'tipo-campo-multiple-op form-check-label d-block') do
          check_box_tag("campo_#{campo.id}[]", opt[:value], false, class: 'form-check-input me-2') +
            opt[:label].to_s
        end
      end.join.html_safe
    end
  end

  # Selección única → Lista desplegable
  def render_single_select(campo)
    opciones = normalize_opciones(campo)

    content_tag(:div, class: 'tipo-campo-unica') do
      select_tag(
        "campo_#{campo.id}",
        options_for_select([['Seleccione una opción', '']]) +
          options_for_select(opciones.map { |o| [o[:label], o[:value]] }),
        class: 'tipo-campo-select form-select'
      )
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
      number_field_tag(
        "campo_#{campo.id}",
        nil,
        class: 'form-control',
        step: 'any',
        placeholder: 'Ingrese un valor numérico'
      )
    end
  end

  # Barra de progreso con descripción
  def render_progress_bar(campo)
    content_tag(:div, class: 'campo-progreso w-100') do
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

      descripcion = content_tag(:div, class: 'campo-texto mt-2 w-100') do
        text_area_tag(
          "campo_#{campo.id}_desc",
          nil,
          class: 'form-control tipo-campo-texto',
          rows: 2,
          maxlength: 500,
          placeholder: 'Descripción de la valoración...'
        )
      end

      fila_slider + descripcion
    end
  end

  ##############################################
  # PLANTEL DOCENTE (mantengo tu lógica)
  ##############################################
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
            concat render_fila_plantel(campo, fila[:nivel], fila[:numero], fila[:materia])
          end

          if defined?(@materias) && @materias.respond_to?(:current_page)
            concat(
              content_tag(:tr, class: 'paginationTr') do
                content_tag(:td, colspan: 5) do
                  content_tag(
                    :div,
                    paginate(@materias, params: request.query_parameters, remote: false),
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
        content_tag(:td, materia.to_s) +
        content_tag(:td) do
          check_box_tag('materias[][se_dicta]', '1', true)
        end +
        content_tag(:td) do
          content_tag(:div, class: 'docentes-container', data: { materia: materia }) do
            content_tag(:div, 'Sin docentes cargados', class: 'docentes-empty') +
              render_boton_agregar_docente(campo, materia)
          end
        end
    end
  end

  ##############################################
  # MODAL DOCENTE (dejado igual que tu base)
  ##############################################
  def render_modal_docente(campo)
    content_tag(:div,
      id: "modal_docente_#{campo.id}",
      title: 'Carga de Docente',
      style: 'display:none;'
    ) do
      render_modal_docente_contenido(campo)
    end
  end

  # Mantengo el pipeline que ya tenías; asumí que estos métodos existen en tu helper:
  # render_stepper, render_step_identificacion, render_step_datos_personales,
  # render_step_desempeno_academico, render_step_investigacion, render_step_datos_laborales, render_step_footer
  def render_modal_docente_contenido(campo)
    render_stepper +
      render_step_identificacion +
      render_step_datos_personales +
      render_step_desempeno_academico +
      render_step_investigacion +
      render_step_datos_laborales +
      render_step_footer
  end

  ##############################################
  # Fallback genérico
  ##############################################
  def render_generic_field(campo)
    text_field_tag("campo_#{campo.id}", nil, class: 'form-control', placeholder: 'Campo genérico')
  end

  ##############################################
  # COMUNES (adaptadas a tu preview actual)
  ##############################################
  def render_pregunta_orientadora(campo)
    texto = campo.try(:pregunta_orientadora).to_s.strip
    return if texto.blank?

    content_tag(:div, texto, class: 'campo-orientadora alert alert-info mt-2 p-2 small')
  end

  def render_attachment_if_allowed(campo)
    permite = campo.try(:permite_archivos)
    permitido = (permite == true) || (permite.to_s == "1")
    return unless permitido

    tipo = campo.try(:tipo_campo).try(:nombre).to_s.downcase
    return unless (tipo =~ /texto/)

    content_tag(:div, class: 'campo-adjunto mt-2') do
      label_tag("adjunto_#{campo.id}", "Adjuntar archivo:", class: 'form-label') +
        file_field_tag("adjunto_#{campo.id}", class: 'campo-adjunto form-control-file')
    end
  end

  # Normaliza opciones para que ande con:
  # - OpenStruct(id:, nombre_opcion:)
  # - o (si existiera) opt.valor / opt.opcion
  def normalize_opciones(campo)
    raw = campo.try(:opciones_campos) || []

    raw.map do |opt|
      label =
        opt.try(:opcion).presence ||
        opt.try(:nombre_opcion).presence ||
        opt.try(:nombre).presence ||
        opt.to_s

      value =
        opt.try(:valor).presence ||
        opt.try(:id).presence ||
        label

      { label: label, value: value }
    end
  end

  ##############################################
  # Utils que ya tenías (los dejo por compatibilidad)
  ##############################################
  def materias_para_plantel
    filas =
      if defined?(@materias) && @materias.any?
        @materias
      else
        materias_mockeadas
      end

    filas.map do |m|
      codigo = m['codigo_materia'] || m[:codigo_materia]
      nombre = m['nombre']         || m[:nombre]
      parsed = parse_codigo_materia(codigo)

      { nivel: parsed[:nivel], numero: parsed[:numero], materia: nombre }
    end
  end

  def materias_mockeadas
    [
      { codigo_materia: '5-2023-101', nombre: 'Didáctica General' },
      { codigo_materia: '5-2023-202', nombre: 'Práctica Docente I' }
    ]
  end

  def parse_codigo_materia(codigo)
    return { nivel: nil, numero: nil } if codigo.blank?

    parte = codigo.to_s.split('-')[2]
    return { nivel: nil, numero: nil } if parte.blank?

    nivel  = parte[0]
    numero = parte.length > 1 ? parte[1..-1] : nil

    { nivel: nivel, numero: numero }
  end

  ##############################################
  # PDF helper (lo dejo como lo tenías)
  ##############################################
  def etapa(pdf, titulo, texto)
    pdf.text titulo, style: :bold, size: 11
    pdf.move_down 4
    pdf.text texto, size: 11, align: :justify, leading: 3
    pdf.move_down 10
  end

  def get_nombre_dimension(num)
    case num.to_i
    when 2 then "Curricular"
    when 1 then "Actividad Docente"
    when 3 then "Organizacional"
    when 4 then 'Actividad del Estudiantado'
    when 5 then 'Desarrollo Academico'
    else "-"
    end
  end
end
