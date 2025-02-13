class CreateLtiUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :lti_users do |t|
      t.string :user_lti_id, null: false
      t.string :lms_id, null: false
      t.string :lms_family
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, type: :integer
  
      t.timestamps
    end
  end
end
