class Campo < ActiveRecord::Base
  self.table_name = 'campos'

  belongs_to :componente
  has_many :subcampos, -> { order(:posicion) }, dependent: :destroy
  accepts_nested_attributes_for :subcampos, allow_destroy: true
  
  has_many :opciones_campos, class_name: 'OpcionCampo', dependent: :destroy, inverse_of: :campo
  accepts_nested_attributes_for :opciones_campos, allow_destroy: true, reject_if: :all_blank

  belongs_to :tipo_campo, class_name: 'TipoCampo', foreign_key: 'tipo_campo_id', optional: true

  before_save :reindex_subcampos

  private
  
  def set_defaults
    self.obligatorio = 1 if obligatorio.nil?
    self.activo = 1 if activo.nil?
    self.tiene_pregunta_orientadora = 0 if tiene_pregunta_orientadora.nil?
    self.permite_adjuntos = 0 if permite_adjuntos.nil?
    self.autoevaluacion = 0 if autoevaluacion.nil?
  end

  def reindex_subcampos
    i = 1
    subcampos.reject(&:marked_for_destruction?).each do |s|
      s.posicion = i
      i += 1
    end
  end
end
