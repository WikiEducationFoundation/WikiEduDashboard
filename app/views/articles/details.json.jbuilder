# frozen_string_literal: true

json.article_details do
  json.startDate @course.start
  json.endDate @course.end
  json.articleTitle @article.escaped_full_title
  json.apiUrl @article.wiki.api_url
  json.wiki do
    json.project @article.wiki.project
    json.language @article.wiki.language
  end

  json.editors do
    json.array! @editors.map(&:username)
  end
end
