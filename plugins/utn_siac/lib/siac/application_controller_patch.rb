module Siac
  module ApplicationControllerPatch
    def self.included(base)
      base.before_action :restrict_siac_cliente_access
    end

    private

    def restrict_siac_cliente_access
      return unless User.current.logged?
      return unless SiacCliente.exists?(user_id: User.current.id, activo: true)

      allowed = {
        'siac_cliente' => %w[index new create buscar_empresa_nosis],
        'siac_cliente_web/convocatorias' => %w[index new create], 
        'siac_docentes' => %w[buscar_por_cuit],
        'account' => %w[logout login]
        
      }

      actions = allowed[controller_path]
      return if actions&.include?(action_name)

      redirect_to siac_cliente_path
    end


  end
end
