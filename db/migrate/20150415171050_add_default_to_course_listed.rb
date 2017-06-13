class AddDefaultToCourseListed < ActiveRecord::Migration[4.2]
  def self.up
    change_column_default :courses, :listed, false
    change_column_default :courses, :published, false
    change_column_default :courses, :approved, false
  end

  def self.down
    change_column_default :courses, :listed, nil
    change_column_default :courses, :published, nil
    change_column_default :courses, :approved, nil
  end
end
