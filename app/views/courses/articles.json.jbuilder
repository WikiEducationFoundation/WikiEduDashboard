# frozen_string_literal: true

json.course do
  json.articles @course.articles_courses.includes(article: :wiki).limit(@limit) do |ac|
    article = ac.article
    json.call(ac, :character_sum, :references_count, :view_count, :new_article, :tracked, :user_ids)
    json.call(article, :id, :namespace, :rating, :deleted, :mw_page_id, :url)
    json.view_count view_count(ac.first_revision, article.average_views, ac.view_count)
    json.title article.full_title
    json.language article.wiki.language
    json.project article.wiki.project
    json.rating_num rating_priority(article.rating)
    json.pretty_rating rating_display(article.rating)
  end
end
