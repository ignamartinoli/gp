module Siac
  class SiacRepository < ActiveRecord::Base
    self.abstract_class = true

    # 🔑 ESTA conexión ES Postgres SIAC
    establish_connection :postgres_siac

    # =========================
    # FUNCTIONS (SELECT)
    # =========================
    def self.function(nombre, *params)
      placeholders = params.map { '?' }.join(', ')
      sql = "SELECT * FROM #{nombre}(#{placeholders})"

      connection.exec_query(
        sanitize_sql_array([sql, *params])
      ).to_a
    end

    # =========================
    # PROCEDURES (CALL)
    # =========================
    def self.procedure(nombre, *params)
      placeholders = params.map { '?' }.join(', ')
      sql = "CALL #{nombre}(#{placeholders})"

      connection.execute(
        sanitize_sql_array([sql, *params])
      )
    end

    # =========================
    # RAW QUERIES
    # =========================
    def self.query(sql)
      connection.exec_query(sql).to_a
    end
  end
end
