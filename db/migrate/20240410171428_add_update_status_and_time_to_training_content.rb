class AddUpdateStatusAndTimeToTrainingContent < ActiveRecord::Migration[7.0]
  def change
    add_column :training_libraries, :update_status, :integer, default: 0
    add_column :training_libraries, :update_error, :string

    add_column :training_modules, :update_status, :integer, default: 0
    add_column :training_modules, :update_error, :string

    add_column :training_slides, :update_status, :integer, default: 0
    add_column :training_slides, :update_error, :string
  end
end
