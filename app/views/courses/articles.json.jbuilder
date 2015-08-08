json.course do
  json.articles @course.articles_courses.live.eager_load(:article) do |ac|
    json.(ac, :character_sum, :view_count, :new_article)
    json.(ac.article, :id, :namespace, :rating)
    json.title full_title(ac.article)
    if ac.article.language.present? && ac.article.language != Figaro.env.wiki_language
      json.language ac.article.language
    end
    json.url article_url(ac.article)
    json.rating_num rating_priority(ac.article.rating)
    json.pretty_rating rating_display(ac.article.rating)
  end
end
