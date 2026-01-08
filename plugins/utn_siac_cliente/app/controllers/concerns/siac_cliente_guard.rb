module SiacClienteGuard
  extend ActiveSupport::Concern

  included do
    before_action :block_non_siac_access
  end

  private

  def block_non_siac_access
    return unless User.current.logged?
    return if User.current.allowed_to?(:view_siac_cliente, nil, global: true)
    # 👆 SI TIENE PERMISO → NO BLOQUEAR

    allowed = {
      'siac_cliente' => %w[index new create],
      'siac_cliente_web/convocatorias' => %w[index new create],
      'account' => %w[index show edit update]
    }

    actions = allowed[controller_path]
    return if actions&.include?(action_name)

    render_403
  end
end
