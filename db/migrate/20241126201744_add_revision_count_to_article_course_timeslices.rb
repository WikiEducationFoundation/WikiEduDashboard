class AddRevisionCountToArticleCourseTimeslices < ActiveRecord::Migration[7.0]
  def change
    add_column :article_course_timeslices, :revision_count, :integer, default: 0
  end
end
