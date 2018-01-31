class CreateRequestedAccounts < ActiveRecord::Migration[5.1]
  def change
    create_table :requested_accounts do |t|
      t.integer :course_id
      t.string :username
      t.string :email
      t.timestamps
    end
  end
end
