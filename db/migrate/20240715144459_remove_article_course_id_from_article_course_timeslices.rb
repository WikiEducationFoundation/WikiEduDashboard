class RemoveArticleCourseIdFromArticleCourseTimeslices < ActiveRecord::Migration[7.0]
  def change
    remove_column :article_course_timeslices, :article_course_id, :integer
  end
end
