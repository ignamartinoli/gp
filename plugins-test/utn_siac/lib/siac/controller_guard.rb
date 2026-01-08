# plugins/utn_siac/lib/siac/controller_guard.rb

module Siac
  module ControllerGuard
    def deny_siac_cliente!
      if User.current.siac_cliente?
        render_403
      end
    end
  end
end
