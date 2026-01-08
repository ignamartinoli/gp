RedmineApp::Application.routes.draw do
  post 'cf_modifications/:id/convert_field',
       to: 'cf_modifications#convert_field',
       as: 'convert_field_cf_modifications'
end
