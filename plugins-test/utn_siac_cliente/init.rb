Redmine::Plugin.register :utn_siac_cliente do
  name 'UTN SIAC Cliente'
  author 'UTN'
  version '1.0.0'

  menu :top_menu, :siac_cliente,
      { controller: '/siac_cliente', action: 'index' },
      caption: 'Convocatorias',
      if: Proc.new { User.current.siac_cliente? }

  permission :view_siac_cliente,
    {
      siac_cliente: [:index, :new, :create]
    },
    public: false

end

Rails.application.config.to_prepare do
  # Ocultar "Proyectos" del menú superior SOLO para SIAC Cliente
  Redmine::MenuManager.map :top_menu do |menu|
    node = menu.find(:projects)
    node.instance_variable_set(
      :@condition,
      Proc.new { !User.current&.siac_cliente? }
    ) if node
  end

  require_dependency 'siac_convocatoria_cliente'
  require_dependency 'siac_cliente'
  require_dependency 'siac/hooks'
  require_dependency 'user'
  require_dependency 'siac/user_patch'
  require_dependency 'sede'
  require_dependency 'regional'
  require_dependency 'especialidad'

  User.include Siac::UserPatch

end