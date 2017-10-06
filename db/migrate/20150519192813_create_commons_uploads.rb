class CreateCommonsUploads < ActiveRecord::Migration[4.2]
  def change
    create_table :commons_uploads do |t|
      t.integer :user_id
      t.string :file_name
      t.datetime :uploaded_at
      t.integer :usage_count
      t.timestamps
    end
  end
end
