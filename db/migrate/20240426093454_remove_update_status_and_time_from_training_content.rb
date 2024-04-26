class RemoveUpdateStatusAndTimeFromTrainingContent < ActiveRecord::Migration[7.0]
  def change
    remove_column :training_libraries, :update_status
    remove_column :training_libraries, :update_error

    remove_column :training_modules, :update_status
    remove_column :training_modules, :update_error

    remove_column :training_slides, :update_status
    remove_column :training_slides, :update_error
  end
end
