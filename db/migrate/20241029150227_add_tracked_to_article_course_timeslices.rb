class AddTrackedToArticleCourseTimeslices < ActiveRecord::Migration[7.0]
  def change
    add_column :article_course_timeslices, :tracked, :boolean, default: true
  end
end
