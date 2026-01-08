module Siac
  class CentrosInvestigacion
    def self.call
      sql = <<~SQL
        SELECT
          id_centro,
          denominacion
        FROM "SIAC_CentrosInvestigacion"
        ORDER BY denominacion;
      SQL

      SiacRecord.connection.exec_query(
        sql,
        "SiacCentrosInvestigacion"
      ).to_a
    end
  end
end
