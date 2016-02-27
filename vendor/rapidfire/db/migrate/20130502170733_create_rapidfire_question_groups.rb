class CreateRapidfireQuestionGroups < ActiveRecord::Migration
  def change
    create_table :rapidfire_question_groups do |t|
      t.string  :name
      t.timestamps
    end
  end
end
