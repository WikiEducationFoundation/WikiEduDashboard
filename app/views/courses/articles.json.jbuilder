# frozen_string_literal: true

json.course do
  json.articles @course.articles_courses.live.includes(article: :wiki) do |ac|
    article = ac.article
    json.call(ac, :character_sum, :view_count, :new_article)
    json.call(article, :id, :namespace, :rating)
    json.title full_title(article)
    json.language article.wiki.language
    json.project article.wiki.project
    json.url article_url(article)
    json.rating_num rating_priority(article.rating)
    json.pretty_rating rating_display(article.rating)
  end
end
