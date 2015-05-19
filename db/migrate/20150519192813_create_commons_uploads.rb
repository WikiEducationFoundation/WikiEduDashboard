class CreateCommonsUploads < ActiveRecord::Migration
  def change
    create_table :commons_uploads do |t|

      t.timestamps
    end
  end
end
