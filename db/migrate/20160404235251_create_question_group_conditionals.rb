class CreateQuestionGroupConditionals < ActiveRecord::Migration[4.2]
  def change
    create_table :question_group_conditionals do |t|
      t.belongs_to :rapidfire_question_group, index: true
      t.belongs_to :cohort, index: true
      t.timestamps null: false
    end

    add_column :rapidfire_question_groups, :tags, :string
  end
end
