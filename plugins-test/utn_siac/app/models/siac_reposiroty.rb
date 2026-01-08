class SiacRepository

  def self.function(nombre, *params)
    placeholders = params.map { '?' }.join(', ')
    sql = "SELECT * FROM #{nombre}(#{placeholders})"

    ActiveRecord::Base.connection.exec_query(
      ActiveRecord::Base.send(:sanitize_sql_array, [sql, *params])
    ).to_a
  end

  # 👇 ESTA ES LA CLAVE
  def self.procedure(nombre, *params)
    placeholders = params.map { '?' }.join(', ')
    sql = "CALL #{nombre}(#{placeholders})"

    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.send(:sanitize_sql_array, [sql, *params])
    )
  end
end
