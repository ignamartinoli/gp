class SiacRecord < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :postgres_siac
end
