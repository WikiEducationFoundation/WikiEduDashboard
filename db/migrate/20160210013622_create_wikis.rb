class CreateWikis < ActiveRecord::Migration[4.2]
  def change
    create_table :wikis do |t|
      t.string :language, limit: 16
      t.string :project, limit: 16
    end
    add_index :wikis, [:language, :project], unique: true

    default_wiki = Wiki.find_or_create_by(
      language: ENV['wiki_language'],
      project: 'wikipedia'
    )

    add_column :articles, :wiki_id, :integer, index: true
    add_column :assignments, :wiki_id, :integer, index: true
    add_column :revisions, :wiki_id, :integer, index: true

    reversible do |dir|
      dir.up do
        Article.all.update_all(wiki_id: default_wiki.id)
        Assignment.all.update_all(wiki_id: default_wiki.id)
        Revision.all.update_all(wiki_id: default_wiki.id)
      end
    end
  end
end
