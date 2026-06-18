# frozen_string_literal: true

json.course do
  json.articles @course.articles_courses.includes(article: :wiki).limit(@limit) do |ac|
    article = ac.article
    json.call(ac, :character_sum, :references_count, :view_count, :new_article, :tracked, :user_ids)
    json.call(article, :id, :namespace, :deleted, :mw_page_id, :url)
    json.view_count calculate_view_count(ac.first_revision, ac.average_views, article.average_views,
                                         ac.view_count)
    json.average_views ac.average_views || article.average_views
    json.title article.full_title
    json.language article.wiki.language
    json.project article.wiki.project
    # Whether this wiki has a LiftWing articlequality model, so the frontend
    # knows whether to offer the article development graphs. Reuses the
    # already-loaded article.wiki (eager-loaded above) — no extra query.
    json.scoreable LiftWingApi.valid_wiki?(article.wiki)
    json.rating_num rating_priority(article.rating)
    json.pretty_rating rating_display(article.rating)
    json.rating default_class(article.rating)
  end
end
