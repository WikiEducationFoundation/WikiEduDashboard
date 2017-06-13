class CreateAlerts < ActiveRecord::Migration[4.2]
  def change
    create_table :alerts do |t|
      t.belongs_to :course, index: true
      t.belongs_to :user, index: true
      t.belongs_to :article, index: true
      t.belongs_to :revision, index: true
      t.string :type
      t.datetime :email_sent_at
      t.timestamps null: false
    end
  end
end
