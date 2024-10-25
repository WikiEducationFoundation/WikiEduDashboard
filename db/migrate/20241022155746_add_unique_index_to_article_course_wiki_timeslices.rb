class AddUniqueIndexToArticleCourseWikiTimeslices < ActiveRecord::Migration[7.0]
  def change
    add_index :article_course_timeslices, [:article_id, :course_id, :start, :end], unique: true, name: 'article_course_timeslice_by_article_course_start_and_end'
  end
end
