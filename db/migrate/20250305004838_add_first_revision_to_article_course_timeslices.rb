class AddFirstRevisionToArticleCourseTimeslices < ActiveRecord::Migration[7.0]
  def change
    add_column :article_course_timeslices, :first_revision, :datetime
  end
end
