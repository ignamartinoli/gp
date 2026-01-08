# plugins/utn_siac_cliente/config/routes.rb
RedmineApp::Application.routes.draw do

  # config/routes.rb
  get 'siac_cliente', to: 'siac_cliente#index', as: :siac_cliente
  get 'siac_cliente/convocatorias/:id', to: 'siac_cliente#new', as: :siac_cliente_convocatoria
  post 'siac_cliente/convocatorias/:id', to: 'siac_cliente#create'

  get 'siac_docentes/buscar_por_cuit', to: 'siac_docentes#buscar_por_cuit'  

  post 'siac_cliente/buscar_empresa_nosis', to: 'siac_cliente#buscar_empresa_nosis'
end
