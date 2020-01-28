# frozen_string_literal: true

if @campaign
  json.campaign do
    json.id @campaign.id
    json.title @campaign.title
    json.slug @campaign.slug
    json.description @campaign.description
    json.template_description @campaign.template_description
    json.default_course_type @campaign.default_course_type
    json.default_passcode @campaign.default_passcode
    json.courses_count @presenter.courses.count  
    json.user_count @presenter.user_count
    json.new_article_count_human number_to_human(@presenter.courses.sum(:new_article_count))
    json.word_count_human number_to_human(@presenter.word_count)
    json.references_count_human number_to_human(@presenter.references_count)
    json.view_sum_human number_to_human(@presenter.courses.sum(:view_sum))
    json.article_count_human number_to_human(@presenter.courses.sum(:article_count))
    json.upload_count_human number_to_human(@presenter.courses.sum(:upload_count))
    json.uploads_in_use_count_human number_to_human(@presenter.uploads_in_use_count)
    json.uploads_in_use_count @presenter.uploads_in_use_count
    json.upload_usage_count_human number_to_human(@presenter.upload_usage_count)
    json.upload_usage_count @presenter.upload_usage_count
    json.trained_percent_human number_to_human(@presenter.trained_percent)
    json.course_string_prefix @presenter.course_string_prefix 
    # json.editable @campaign.editable
    json.register_accounts @campaign.register_accounts
    json.requested_accounts @campaign.requested_accounts
    json.organizers @campaign.organizers
    json.open_course_creation @campaign.open_course_creation
    json.createCourseEnabled @campaign.createCourseEnabled
  end
end

