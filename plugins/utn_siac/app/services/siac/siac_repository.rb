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
      # typed_params = [{ value: ..., cast: "boolean" }, ...]
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


    def self.pg_int_array_literal(arr)
      a = Array(arr).compact.reject(&:blank?).map(&:to_i)
      "{#{a.join(',')}}"
    end

    def self.pg_varchar_array_literal(arr)
      a = Array(arr).compact.reject(&:blank?).map(&:to_s)
      return nil if a.empty?
      # En literal PG, strings van con comillas dobles si hay caracteres especiales;
      # como mínimo escapamos comillas dobles.
      escaped = a.map { |s| s.gsub('"', '\"') }
      "{#{escaped.join(',')}}"
    end

    def self.procedure_typed(nombre, typed_params)
      # typed_params = [{ value: ..., cast: "integer[]" }, ...]
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
  end
end
