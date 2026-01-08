# Plugin's routes
get 'project/:id/goals', :to => 'goals#index', :as => "goals"
get 'exporter/:id.:format', :to => 'exporter#to_doc', :as=>"export_to_docx"
get 'exporter/gestion/:id.:format', :to => 'exporter#gestion_to_doc', :as=>"export_gestion_to_docx"
put "project/:id/update_settings",:to => 'goals#update_settings', :as=>"save_cmi_settings"
get 'project/:id/reporte_indicador/:id_ind', :to => 'goals#reporte_indicador', :as => "reporte_indicador"
get 'project/:id/reporte_cmi', :to => 'goals#reporte_cmi', :as => "reporte_cmi"
resources :issues do
  resources :historic_values, on: :member
end
