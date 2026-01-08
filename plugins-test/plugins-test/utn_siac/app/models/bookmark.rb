class Bookmark < ActiveRecord::Base
  belongs_to :convocatoria
  # No necesitamos belongs_to :user ya que no estamos creando un modelo User

  validates :user_id, presence: true # Aseguramos que user_id esté presente

  # Valida que una convocatoria no se repita para el mismo usuario
  validates :convocatorias_id, uniqueness: { scope: :user_id, message: "Ya tienes esta convocatoria en tus favoritos" }
end
