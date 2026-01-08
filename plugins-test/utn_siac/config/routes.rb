# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'convocatorias', to: 'convocatoria#index'
get 'convocatorias/nueva', to: 'convocatoria#new', as: 'new_convocatoria'
post 'convocatorias', to: 'convocatoria#create', as: 'create_convocatoria'
delete 'convocatorias/:id', to: 'convocatoria#destroy', as: 'delete_convocatoria'
get 'convocatorias/:id', to: 'convocatoria#show', as: 'show_convocatoria'
patch 'convocatorias/:id', to: 'convocatoria#update', as: 'update_convocatoria'
get 'convocatorias/:id/editar', to: 'convocatoria#edit', as: 'edit_convocatoria'
get 'convocatorias/:id/preview', to: 'convocatoria#preview', as: 'preview_convocatoria'
get 'convocatorias/:id/bookmark', to: 'convocatoria#bookmark', as: 'bookmark_convocatoria'
get 'convocatorias/:id/unbookmark', to: 'convocatoria#unbookmark', as: 'unbookmark_convocatoria'
get 'convocatorias/buscar', to: 'convocatoria#buscar', as: 'buscar_convocatoria'
get 'convocatorias/cargar_especialidades/:titulacion', to: 'convocatoria#cargar_especialidades', as: 'cargar_especialidades_convocatoria'
post 'convocatorias/cargar_sedes', to: 'convocatoria#cargar_sedes', as: 'cargar_especialidades_sedes'
post "convocatorias/pdf_preview", to: "convocatoria#pdf_preview"

# Administrar Componentes
get 'componentes', to: 'componente#index', as: 'componentes'
get 'componentes/nueva', to: 'componente#new', as: 'new_componente'
post 'componentes', to: 'componente#create', as: 'create_componente'
delete 'componentes/:id', to: 'componente#destroy', as: 'delete_componente'
get 'componentes/:id', to: 'componente#show', as: 'show_componente'
patch 'componentes/:id', to: 'componente#update', as: 'update_componente'
get 'componentes/:id/editar', to: 'componente#edit', as: 'edit_componente'
get 'componentes/:id/preview', to: 'componente#preview', as: 'preview_componente'

#Siac
get 'siac/personas_convocatoria', to: 'siac#personas_convocatoria'

namespace :siac do
  namespace :docentes do
    get  'buscar',    to: 'docentes#buscar'
    get  'datos',     to: 'docentes#datos'
    get  'catalogos', to: 'docentes#catalogos'
    post 'guardar',   to: 'docentes#guardar'
  end
end

get 'siac/cargos_docentes', to: 'siac#cargos_docentes'