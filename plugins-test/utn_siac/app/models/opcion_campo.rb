class OpcionCampo < ActiveRecord::Base
  self.table_name = 'opciones_campos'

  belongs_to :campo, optional: true
  belongs_to :subcampo, optional: true

  validates :opcion, presence: true
  validates :valor, presence: true

  # ✅ Validación ajustada para permitir guardado en cascada
  validate :solo_un_tipo_asociacion

  private

  def solo_un_tipo_asociacion
    # Si la opción está siendo creada dentro de un campo nuevo (aún sin ID), no validar todavía
    return if campo_id.blank? && campo.present? && campo.new_record?
    return if subcampo_id.blank? && subcampo.present? && subcampo.new_record?

    if campo_id.present? && subcampo_id.present?
      errors.add(:base, "La opción no puede pertenecer a un campo y un subcampo al mismo tiempo.")
    elsif campo_id.blank? && subcampo_id.blank?
      errors.add(:base, "Debe asociarse a un campo o a un subcampo.")
    end
  end
end
