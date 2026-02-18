# frozen_string_literal: true

module Siac
  class ConvocatoriaDto
    attr_reader :id, :resolucion, :nombre, :fecha_inicio, :fecha_hasta,
                :titulaciones, :tipo_especialidad, :etapa, :estado

    def initialize(id:, resolucion:, nombre:, fecha_inicio:, fecha_hasta:, titulaciones:, tipo_especialidad:, etapa:, estado:)
      @id = id
      @resolucion = resolucion
      @nombre = nombre
      @fecha_inicio = fecha_inicio
      @fecha_hasta = fecha_hasta
      @titulaciones = titulaciones
      @tipo_especialidad = tipo_especialidad
      @etapa = etapa
      @estado = estado
    end
  end
end
