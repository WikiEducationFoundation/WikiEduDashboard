class AddHomeWikiIdToCourse < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :home_wiki_id, :integer
    Course.where(home_wiki_id: nil).update_all(home_wiki_id: 1)
  end
end
