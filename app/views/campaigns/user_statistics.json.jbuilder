# frozen_string_literal: true
json.campaigns @values do |campaign|
  presenter = CoursesPresenter.new(
    current_user: current_user,
    campaign_param: campaign.slug
  )
  json.call(campaign, :id, :title, :slug)
  json.call(
    presenter,
    :course_count,
    :new_article_count,
    :article_count,
    :word_count,
    :references_count,
    :view_sum,
    :user_count,
    :creation_date
  )
  json.human_course_count number_to_human(presenter.course_count)
  json.human_new_article_count number_to_human(presenter.new_article_count)
  json.human_article_count number_to_human(presenter.article_count)
  json.human_word_count number_to_human(presenter.word_count)
  json.human_references_count number_to_human(presenter.references_count)
  json.human_view_sum number_to_human(presenter.view_sum)
end
