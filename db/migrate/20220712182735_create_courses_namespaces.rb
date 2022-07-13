class CreateCoursesNamespaces < ActiveRecord::Migration[6.1]
  def change
    create_table :courses_namespaces do |t|
      t.integer :namespace
      t.references :courses_wikis, index: true, foreign_key: {on_delete: :cascade}

      t.timestamps
    end
  end
end
