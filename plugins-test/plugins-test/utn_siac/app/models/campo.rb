class Campo < ActiveRecord::Base
  self.table_name = 'campos'

  belongs_to :tipo_campo
  belongs_to :componente

  before_validation :set_defaults

  private

  def set_defaults
    self.obligatorio = 0 if obligatorio.nil?
    self.activo = 1 if activo.nil?  # Asegura que activo sea 1 por defecto
    self.tiene_pregunta_orientadora = 1 if tiene_pregunta_orientadora.nil?;
  end
end

