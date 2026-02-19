# plugins/utn_siac/lib/siac/controller_guard.rb

module Siac
  module ControllerGuard
    def deny_siac_cliente!
      return unless User.current&.logged?

      if SiacCliente.exists?(user_id: User.current.id, activo: true)
        render_403
      end
    end
  end
end
