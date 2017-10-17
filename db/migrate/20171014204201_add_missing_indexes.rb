class AddMissingIndexes < ActiveRecord::Migration[5.1]
  def change
    add_index :alerts, :subject_id
    add_index :articles, :wiki_id
    add_index :articles, :title
    add_index :assignment_suggestions, :user_id
    add_index :assignments, :article_id
    add_index :assignments, :course_id
    add_index :assignments, :user_id
    add_index :assignments, :wiki_id
    add_index :blocks, :gradeable_id
    add_index :campaigns_courses, :campaign_id
    add_index :campaigns_courses, :course_id
    add_index :courses, :chatroom_id
    add_index :courses, :home_wiki_id
    add_index :feedback_form_responses, :user_id
    add_index :gradeables, :gradeable_item_id
    add_index :rapidfire_answer_groups, :course_id
    add_index :revisions, :ithenticate_id
    add_index :revisions, :mw_page_id
    add_index :revisions, :mw_rev_id
    add_index :training_modules_users, :training_module_id
    add_index :user_profiles, :user_id
    add_index :users, :chat_id
    add_index :users, :global_id
  end
end
