class AddTrackedIndexToArticleCourseTimeslices < ActiveRecord::Migration[7.0]
  def change
    add_index :article_course_timeslices, [:course_id, :tracked], name: 'article_course_timeslice_by_tracked'
  end
end
