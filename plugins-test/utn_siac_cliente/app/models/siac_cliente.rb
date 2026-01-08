class SiacCliente < ActiveRecord::Base
  self.table_name = 'siac_clientes'

  belongs_to :user
  belongs_to :regional

  # Jerarquía
  belongs_to :parent,
             class_name: 'SiacCliente',
             optional: true

  has_many :hijos,
           class_name: 'SiacCliente',
           foreign_key: 'parent_id',
           dependent: :nullify

  # Scopes útiles
  scope :activos, -> { where(activo: true) }
  scope :padres,  -> { where(parent_id: nil) }

  def padre?
    parent_id.nil?
  end

  def hijo?
    parent_id.present?
  end
end
