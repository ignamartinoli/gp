Rails.application.routes.draw do
  post 'cf_modifications/:id/convert', to: 'cf_modifications#convert_field', as: 'convert_cf'
end
