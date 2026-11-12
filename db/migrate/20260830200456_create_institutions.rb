class CreateInstitutions < ActiveRecord::Migration[8.1]
  def change
    create_table :institutions, charset: "utf8mb4", collation: "utf8mb4_unicode_ci" do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :institutions, :name, unique: true
  end
end
