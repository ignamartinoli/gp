# frozen_string_literal: true

require "yaml"
require "prawn"
require "prawn/table"

require_relative "template_renderer"

module Siac
  module Convocatoria
    class PdfGenerator
      HEADER_H = 85
      FOOTER_H = 45

      def initialize(data:, template_path:, strict_placeholders: true)
        @data = data
        @spec = YAML.load_file(template_path)
        @renderer = TemplateRenderer.new(values: placeholder_values(@data), strict: strict_placeholders)
      end

    def render
    pdf = Prawn::Document.new(
        page_size: "A4",
        margin: [HEADER_H + 30, 60, FOOTER_H + 25, 60]
    )

    setup_utf8_font!(pdf)
    header(pdf)
    footer(pdf)

    Array(@spec["sections"]).each do |section|
        render_section(pdf, section)
    end

    pdf.render
    rescue => e
    Rails.logger.error("[SIAC][PDF][GEN] EXCEPTION #{e.class}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    puts "[SIAC][PDF][GEN] EXCEPTION #{e.class}: #{e.message}"
    puts e.backtrace.first(30).join("\n")
    raise
    end

      private

      # ---------------------------
      # Keep together compat (Prawn 2.4 no tiene keep_together)
      # ---------------------------
      def with_keep_together(pdf, &block)
        if pdf.respond_to?(:keep_together)
          pdf.keep_together(&block)
        elsif pdf.respond_to?(:group)
          pdf.group(&block)
        else
          yield
        end
      end

      # ---------------------------
      # Fonts (UTF-8)
      # ---------------------------
      def setup_utf8_font!(pdf)
        Prawn::Fonts::AFM.hide_m17n_warning = true

        font_sets = [
          {
            normal: "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
            bold: "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
            italic: "/usr/share/fonts/truetype/dejavu/DejaVuSans-Oblique.ttf",
            bold_italic: "/usr/share/fonts/truetype/dejavu/DejaVuSans-BoldOblique.ttf"
          },
          {
            normal: "/usr/share/fonts/dejavu/DejaVuSans.ttf",
            bold: "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf",
            italic: "/usr/share/fonts/dejavu/DejaVuSans-Oblique.ttf",
            bold_italic: "/usr/share/fonts/dejavu/DejaVuSans-BoldOblique.ttf"
          },
          {
            normal: Rails.root.join("plugins/utn_siac/assets/fonts/DejaVuSans.ttf").to_s,
            bold: Rails.root.join("plugins/utn_siac/assets/fonts/DejaVuSans-Bold.ttf").to_s,
            italic: Rails.root.join("plugins/utn_siac/assets/fonts/DejaVuSans-Oblique.ttf").to_s,
            bold_italic: Rails.root.join("plugins/utn_siac/assets/fonts/DejaVuSans-BoldOblique.ttf").to_s
          }
        ]

        font_set = font_sets.find do |fs|
          File.exist?(fs[:normal].to_s) && File.exist?(fs[:bold].to_s)
        end

        unless font_set
          Rails.logger.warn(
            "[SIAC][PDF] No UTF-8 font set found (need DejaVuSans normal+bold). " \
            "Install fonts-dejavu in the container or add TTFs under plugins/utn_siac/assets/fonts."
          )
          return
        end

        pdf.font_families.update(
          "DejaVuSans" => {
            normal: font_set[:normal].to_s,
            bold: font_set[:bold].to_s,
            italic: font_set[:italic]&.to_s,
            bold_italic: font_set[:bold_italic]&.to_s
          }.compact
        )

        pdf.font("DejaVuSans")
      end

      # ---------------------------
      # Placeholders
      # ---------------------------
      def placeholder_values(c)
        fin = c.respond_to?(:fecha_hasta) ? c.fecha_hasta : nil

        f_cap = c.respond_to?(:fecha_fin_capacitacion) ? c.fecha_fin_capacitacion : nil
        f_car = c.respond_to?(:fecha_fin_carga) ? c.fecha_fin_carga : nil
        f_rev = c.respond_to?(:fecha_fin_revision) ? c.fecha_fin_revision : nil
        f_cor = c.respond_to?(:fecha_fin_correcciones) ? c.fecha_fin_correcciones : nil
        f_aud = c.respond_to?(:fecha_fin_auditoria) ? c.fecha_fin_auditoria : nil

        {
          "fecha_hoy" => fmt_date(Time.zone.today),

          "resolucion" => safe_str(c.respond_to?(:resolucion) ? c.resolucion : nil),
          "nombre" => safe_str(c.respond_to?(:nombre) ? c.nombre : nil),

          "fecha_inicio" => fmt_date(c.respond_to?(:fecha_inicio) ? c.fecha_inicio : nil),
          "fecha_hasta"  => fmt_date(fin),

          "fecha_fin_capacitacion" => fmt_date(presence_or(f_cap, fin)),
          "fecha_fin_carga"        => fmt_date(presence_or(f_car, fin)),
          "fecha_fin_revision"     => fmt_date(presence_or(f_rev, fin)),
          "fecha_fin_correcciones" => fmt_date(presence_or(f_cor, fin)),
          "fecha_fin_auditoria"    => fmt_date(presence_or(f_aud, fin))
        }
      end

      def presence_or(a, b)
        return a if a.present?
        b
      end

      def fmt_date(d)
        return "-" if d.blank?
        dd = d.respond_to?(:to_date) ? d.to_date : d
        I18n.l(dd, format: :long)
      rescue StandardError
        "-"
      end

      def safe_str(s)
        s.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
      end

      # ---------------------------
      # Rendering primitives
      # ---------------------------
      def ensure_space!(pdf, min_height)
        pdf.start_new_page if pdf.cursor < min_height
      end

      def render_section(pdf, section)
        type = section.fetch("type")

        case type
        when "heading"
          ensure_space!(pdf, (section["min_space"] || 70))
          with_keep_together(pdf) do
            pdf.text @renderer.render(section["text"]),
                     style: :bold,
                     size: (section["size"] || 12)
            pdf.move_down(section["after"] || 8)
          end

        when "subheading"
          ensure_space!(pdf, (section["min_space"] || 55))
          with_keep_together(pdf) do
            pdf.text @renderer.render(section["text"]),
                     style: :bold,
                     size: (section["size"] || 11)
            pdf.move_down(section["after"] || 6)
          end

        when "paragraph"
          ensure_space!(pdf, (section["min_space"] || 70))
          pdf.text @renderer.render(section["text"]),
                   size: (section["size"] || 11),
                   align: (section["align"] || :justify).to_sym,
                   leading: (section["leading"] || 3)
          pdf.move_down(section["after"] || 12)

        when "right_paragraph"
          ensure_space!(pdf, (section["min_space"] || 45))
          pdf.text @renderer.render(section["text"]),
                   size: (section["size"] || 11),
                   align: :right,
                   leading: (section["leading"] || 3)
          pdf.move_down(section["after"] || 12)

        when "bullets"
          ensure_space!(pdf, (section["min_space"] || 90))
          with_keep_together(pdf) do
            if section["title"].present?
              pdf.text @renderer.render(section["title"]),
                       style: :bold,
                       size: (section["title_size"] || 11)
              pdf.move_down(section["title_after"] || 4)
            end

            Array(section["items"]).each do |it|
              pdf.text "• #{@renderer.render(it)}",
                       size: (section["size"] || 11),
                       indent_paragraphs: (section["indent"] || 20),
                       leading: (section["leading"] || 3)
            end

            pdf.move_down(section["after"] || 10)
          end

        when "table"
          ensure_space!(pdf, (section["min_space"] || 140))
          render_table(pdf, section)

        when "page_break"
          pdf.start_new_page

        else
          raise ArgumentError, "Unknown section type: #{type.inspect}"
        end
      end

      def render_table(pdf, section)
        data = section.fetch("data").map { |row| row.map { |cell| @renderer.render(cell) } }

        header = (section["header"] == true)
        size = (section["size"] || 9.5)
        padding = (section["padding"] || [6, 6, 6, 6])

        pdf.table(
          data,
          width: pdf.bounds.width,
          header: header,
          row_colors: (section["row_colors"] || ["F7F7F7", "FFFFFF"]),
          cell_style: { size: size, padding: padding }
        ) do
          if header
            row(0).font_style = :bold
            row(0).background_color = (section["header_bg"] || "EAEAEA")
          end

          if section["column_align"].is_a?(Hash)
            section["column_align"].each do |idx, align|
              columns(idx.to_i).align = align.to_sym
            end
          end

          if section["column_widths"].is_a?(Hash)
            widths = {}
            section["column_widths"].each { |k, v| widths[k.to_i] = v.to_i }
            self.column_widths = widths
          end
        end

        pdf.move_down(section["after"] || 12)
      end

      # ---------------------------
      # Header / Footer
      # ---------------------------
      def header(pdf)
        candidates = [
          Rails.root.join("public/plugin_assets/utn_siac/images/utn_logo_capital_humano.png").to_s,
          Rails.root.join("plugins/utn_siac/assets/images/utn_logo_capital_humano.png").to_s
        ]

        logo_path = candidates.find { |p| File.exist?(p) }
        Rails.logger.warn("[SIAC][PDF] Logo NOT FOUND. Tried: #{candidates.join(' | ')}") unless logo_path

        pdf.repeat(:all) do
          pdf.bounding_box([pdf.bounds.left, pdf.bounds.top + HEADER_H], width: pdf.bounds.width, height: HEADER_H) do
            y = pdf.cursor
            pdf.image logo_path, fit: [140, 70], at: [0, y] if logo_path

            pdf.text_box(
              "2025 – Año de la Reconstrucción de la Nación Argentina",
              at: [0, y],
              width: pdf.bounds.width,
              height: 70,
              align: :right,
              valign: :center,
              size: 8,
              style: :bold
            )

            pdf.stroke_color "CCCCCC"
            pdf.stroke_horizontal_rule
            pdf.stroke_color "000000"
          end
        end
      end

      def footer(pdf)
        pdf.number_pages(
          "2025 – Año de la Educación y el Conocimiento para una Sociedad Justa y Democratizadora\nPágina <page>",
          at: [pdf.bounds.left, 35],
          width: pdf.bounds.width,
          align: :center,
          size: 7
        )
      end
    end
  end
end