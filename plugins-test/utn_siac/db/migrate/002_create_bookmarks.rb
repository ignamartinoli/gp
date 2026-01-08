class CreateBookmarks < ActiveRecord::Migration[5.2]
  def change
    create_table :bookmarks do |t|
      t.references :convocatorias, foreign_key: true
      t.integer :user_id, null: false
      t.timestamps
    end
  end
end
