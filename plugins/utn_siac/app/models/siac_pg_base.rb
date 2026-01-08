class SiacPgBase < ActiveRecord::Base
 self.abstract_class = true

 # usa la conexión "siac_pg_development" (ajusta al nombre que pusiste en database.yml)
 establish_connection :postgres_siac
end
