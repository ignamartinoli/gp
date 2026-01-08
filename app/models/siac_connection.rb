# app/models/siac_connection.rb
class SiacConnection < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :postgres_siac
end
