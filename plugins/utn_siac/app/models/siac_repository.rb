class SiacRepository < ApplicationRecord
  self.abstract_class = true

  # =========================
  # FUNCTIONS (SELECT)
  # =========================
  def self.function(nombre, *params)
    placeholders = params.map { '?' }.join(', ')
    sql = "SELECT * FROM #{nombre}(#{placeholders})"

    ActiveRecord::Base.connection.exec_query(
      ActiveRecord::Base.send(:sanitize_sql_array, [sql, *params])
    ).to_a
  end

  # =========================
  # PROCEDURES (CALL)
  # =========================
  def self.procedure(nombre, *params)
    placeholders = params.map { '?' }.join(', ')
    sql = "CALL #{nombre}(#{placeholders})"

    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.send(:sanitize_sql_array, [sql, *params])
    )
  end

  # =========================
  # QUERIES RAW (opcional)
  # =========================
  def self.query(sql)
    ActiveRecord::Base.connection.exec_query(sql).to_a
  end
end
