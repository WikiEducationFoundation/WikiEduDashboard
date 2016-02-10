class DecoupleWikiIds < ActiveRecord::Migration
  def change
    add_column :articles, :native_id, :integer, index: true
    add_column :revisions, :native_id, :integer, index: true
    add_column :revisions, :page_id, :integer, index: true

    reversible do |dir|
      execute %(
        UPDATE articles
          SET native_id = id
      )

      execute %(
        UPDATE revisions
          SET native_id = id,
              page_id = article_id
      )
    end
  end
end
