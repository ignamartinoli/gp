# app/services/siac/convocatoria/template_renderer.rb
# frozen_string_literal: true

module Siac
  module Convocatoria
    class TemplateRenderer
      PLACEHOLDER = /\{\{\s*([a-zA-Z0-9_]+)\s*\}\}/.freeze

      def initialize(values:, strict: true)
        @values = values.transform_keys(&:to_s)
        @strict = strict
      end

      def render(text)
        text.to_s.gsub(PLACEHOLDER) do
          key = Regexp.last_match(1)
          val = @values[key]

          if val.nil?
            raise KeyError, "Missing placeholder: #{key}" if @strict
            "-"
          else
            val.to_s
          end
        end
      end
    end
  end
end