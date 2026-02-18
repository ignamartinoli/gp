module Siac
  class SiacRepository < ActiveRecord::Base
    self.abstract_class = true
    establish_connection :postgres_siac

    def self.function(nombre, *params)
      placeholders = (["?"] * params.length).join(", ")
      sql = "SELECT * FROM #{nombre}(#{placeholders})"

      connection.exec_query(
        sanitize_sql_array([sql, *params])
      ).to_a
    end

    def self.function_typed(nombre, typed_params)
      placeholders = typed_params.map { |p| "?::#{p[:cast]}" }.join(", ")
      sql = "SELECT * FROM #{nombre}(#{placeholders})"
      values = typed_params.map { |p| p[:value] }

      connection.exec_query(
        sanitize_sql_array([sql, *values])
      ).to_a
    end

    def self.procedure(nombre, *params)
      placeholders = (["?"] * params.length).join(", ")
      sql = "CALL #{nombre}(#{placeholders})"

      result = connection.exec_query(
        sanitize_sql_array([sql, *params])
      )

      rows = result.to_a
      rows.length == 1 ? rows.first : rows
    end

    def self.procedure_typed(nombre, typed_params)
      placeholders = typed_params.map { |p| "?::#{p[:cast]}" }.join(", ")
      sql = "CALL #{nombre}(#{placeholders})"
      values = typed_params.map { |p| p[:value] }

      result = connection.exec_query(
        sanitize_sql_array([sql, *values])
      )
      result.to_a
    end

    def self.query(sql)
      connection.exec_query(sql).to_a
    end

    # Devuelve el primer valor de la primera fila o nil.
    # Útil para SELECT id ... LIMIT 1
    def self.select_value(sql, *binds)
      rows = connection.exec_query(
        sanitize_sql_array([sql, *binds])
      ).to_a
      return nil if rows.empty?
      rows.first.values.first
    end

    def self.pg_int_array_literal(arr)
      a = Array(arr).compact.reject(&:blank?).map(&:to_i)
      "{#{a.join(',')}}"
    end

    def self.pg_varchar_array_literal(arr)
      a = Array(arr).compact.reject(&:blank?).map(&:to_s)
      return nil if a.empty?
      escaped = a.map { |s| s.gsub('"', '\"') }
      "{#{escaped.join(',')}}"
    end
  end
end
