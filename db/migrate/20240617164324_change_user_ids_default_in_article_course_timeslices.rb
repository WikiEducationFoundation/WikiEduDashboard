class ChangeUserIdsDefaultInArticleCourseTimeslices < ActiveRecord::Migration[7.0]
  def change
    change_column_default :article_course_timeslices, :user_ids, nil
  end
end
