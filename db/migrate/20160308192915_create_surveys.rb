class CreateSurveys < ActiveRecord::Migration
  def change
    drop_table :surveys
    create_table :surveys do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
