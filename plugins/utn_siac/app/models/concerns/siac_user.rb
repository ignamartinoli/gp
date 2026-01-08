module SiacUser
  extend ActiveSupport::Concern

  def siac_cliente?
    SiacCliente.where(user_id: id, activo: true).exists?
  end


  def siac_sede_ids
    siac_usuario_ambitos.where(activo: true).pluck(:sede_id)
  end
end
