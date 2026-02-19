class DropFkBookmarksConvocatorias < ActiveRecord::Migration[5.2]
  def up
    # elimina FK por nombre (el que aparece en el error)
    execute "ALTER TABLE bookmarks DROP FOREIGN KEY fk_rails_e64f3e4478"
  end

  def down
    execute <<~SQL
      ALTER TABLE bookmarks
      ADD CONSTRAINT fk_rails_e64f3e4478
      FOREIGN KEY (convocatorias_id)
      REFERENCES convocatorias(id)
    SQL
  end
end
