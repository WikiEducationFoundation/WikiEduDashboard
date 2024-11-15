class AddUpdatedAtIndexToArticleCourseWikiTimeslices < ActiveRecord::Migration[7.0]
  def change
    add_index :article_course_timeslices, [:course_id, :updated_at, :article_id], name: 'article_course_timeslice_by_updated_at'
  end
end
