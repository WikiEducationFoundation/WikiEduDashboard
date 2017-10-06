class SetDefaultColumnValues < ActiveRecord::Migration[4.2]
  def change
    change_column_default :articles, :views, 0
    change_column_default :articles, :character_sum, 0
    change_column_default :articles, :revisions_count, 0

    change_column_default :articles_courses, :view_count, 0
    change_column_default :articles_courses, :character_sum, 0

    change_column_default :courses, :character_sum, 0
    change_column_default :courses, :view_sum, 0
    change_column_default :courses, :user_count, 0
    change_column_default :courses, :article_count, 0
    change_column_default :courses, :revision_count, 0

    change_column_default :courses_users, :character_sum, 0

    change_column_default :revisions, :characters, 0
    change_column_default :revisions, :views, 0

    change_column_default :users, :character_sum, 0
    change_column_default :users, :view_sum, 0
    change_column_default :users, :course_count, 0
    change_column_default :users, :article_count, 0
    change_column_default :users, :revisions_count, 0
    change_column_default :users, :trained, false
  end
end
