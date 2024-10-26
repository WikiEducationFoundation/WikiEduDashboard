class AddNewArticleToArticleCourseTimeslices < ActiveRecord::Migration[7.0]
  def change
    add_column :article_course_timeslices, :new_article, :boolean, default: false
  end
end
