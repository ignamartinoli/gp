class Subcampo < ActiveRecord::Base
  self.table_name = 'subcampos'

  belongs_to :campo
  belongs_to :tipo_campo, optional: true

  has_many :opciones_campos, class_name: 'OpcionCampo', dependent: :destroy, inverse_of: :subcampo
  accepts_nested_attributes_for :opciones_campos, allow_destroy: true, reject_if: :all_blank

  validates :pregunta, presence: true
  validates :posicion, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :descripcion, presence: true, if: -> { tiene_pregunta_orientadora.to_i == 1 }

  before_validation :set_defaults

  private

  def set_defaults
    self.obligatorio = 0 if obligatorio.nil?
    self.tiene_pregunta_orientadora = 0 if tiene_pregunta_orientadora.nil?
    self.permite_adjuntos = 0 if permite_adjuntos.nil?
    self.activo = 1 if activo.nil?
  end
end
