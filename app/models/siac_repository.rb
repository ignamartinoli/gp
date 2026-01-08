# app/models/siac_repository.rb
class SiacRepository < SiacConnection
  self.abstract_class = true

  def self.function(nombre, *params)
    placeholders = params.map { '?' }.join(', ')
    sql = sanitize_sql_array([
      "SELECT * FROM #{nombre}(#{placeholders})",
      *params
    ])
    connection.exec_query(sql).to_a
  end
end
