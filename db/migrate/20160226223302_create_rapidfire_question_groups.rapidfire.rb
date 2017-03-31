# This migration comes from rapidfire (originally 20130502170733)
class CreateRapidfireQuestionGroups < ActiveRecord::Migration[4.2]
  def change
    create_table :rapidfire_question_groups do |t|
      t.string  :name
      t.timestamps
    end
  end
end
