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
    json.courses_count number_to_human @presenter.courses.count
    json.user_count number_to_human @presenter.user_count
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
    json.show_the_create_course_button Features.open_course_creation? && current_user&.admin?
    json.editable @editable
    json.register_accounts @campaign.register_accounts
    json.start @campaign.start
    json.end @campaign.end
    json.created_at @campaign.created_at

    if @presenter.wikidata_stats['www.wikidata.org']
      json.course_stats format_course_stats(@presenter.wikidata_stats)
    end
  end
end
