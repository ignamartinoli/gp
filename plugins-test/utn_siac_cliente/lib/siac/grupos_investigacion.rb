module Siac
  class GruposInvestigacion
    def self.call
      sql = <<~SQL
        SELECT
          id_grupo,
          denominacion
        FROM "SIAC_GruposInvestigacion"
        ORDER BY denominacion;
      SQL

      SiacRecord.connection.exec_query(
        sql,
        "SiacGruposInvestigacion"
      ).to_a
    end
  end
end
