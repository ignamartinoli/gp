module Siac
  module UserPatch
    def self.included(base)
      base.has_many :siac_usuario_ambitos
      base.has_many :sedes, through: :siac_usuario_ambitos
    end
  end
end
