class AddInstitutionToCourses < ActiveRecord::Migration[8.1]
  def change
    add_reference :courses, :institution, foreign_key: true
  end
end
