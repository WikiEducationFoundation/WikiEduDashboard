# Exercise state for the course SPA: the student's taken claim (if any) and the
# articles they can choose from (each carrying what the ArticleViewer needs).
if @assignment
  json.assignment { json.partial! 'assignment', assignment: @assignment }
else
  json.assignment nil
end

json.articles @articles do |article|
  json.id article.id
  json.title article.full_title
  json.language article.wiki.language
  json.project article.wiki.project
  json.url article.url
  json.mw_page_id article.mw_page_id
end
