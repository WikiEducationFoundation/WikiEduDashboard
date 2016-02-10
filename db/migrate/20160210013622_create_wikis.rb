class CreateWikis < ActiveRecord::Migration
  def change
    create_table :wikis do |t|
      t.string :language, limit: 16
      t.string :project, limit: 16
    end

    default_wiki = Wiki.create(language: ENV['wiki_language'], project: 'wikipedia')

    add_column :articles, :wiki_id, :integer, index: true
    add_column :assignments, :wiki_id, :integer, index: true
    add_column :revisions, :wiki_id, :integer, index: true

    reversible do |dir|
      dir.up do
        execute %(
          UPDATE articles SET wiki_id = #{default_wiki.id}
        )

        execute %(
          UPDATE assignments SET wiki_id = #{default_wiki.id}
        )

        execute %(
          UPDATE revisions SET wiki_id = #{default_wiki.id}
        )
      end
    end
  end
end
