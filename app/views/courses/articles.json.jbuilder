# frozen_string_literal: true

json.course do
  json.articles @course.articles_courses.all.includes(article: :wiki).limit(@limit) do |ac|
    article = ac.article
    json.call(ac, :character_sum, :references_count, :view_count, :new_article, :tracked)
    json.call(article, :id, :namespace, :rating, :deleted)
    json.title article.full_title
    json.language article.wiki.language
    json.project article.wiki.project
    json.url article.url
    json.rating_num rating_priority(article.rating)
    json.pretty_rating rating_display(article.rating)
    json.user_ids ac.user_ids
  end
end
