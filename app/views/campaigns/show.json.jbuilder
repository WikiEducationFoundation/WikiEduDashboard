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
    json.editors @presenter.user_count
    json.references_count @presenter.references_count
    json.article_views @presenter.view_sum
    json.article_count @presenter.article_count
    json.articles_created @presenter.new_article_count
    json.word_count @presenter.word_count
    json.uploads_in_use_count @presenter.upload_in_use_count
  end
end
