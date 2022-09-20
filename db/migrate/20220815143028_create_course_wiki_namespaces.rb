class CreateCourseWikiNamespaces < ActiveRecord::Migration[7.0]
  def change
    create_table :course_wiki_namespaces do |t|
      t.integer :namespace
      t.references :courses_wikis, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
  end
end
