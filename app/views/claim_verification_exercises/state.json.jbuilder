# Exercise state for the course SPA: the student's taken claim (if any) and the
# (article, flagged-revision) tiles they can choose from. Each tile carries the
# flagged `mw_rev_id` (the ArticleViewer loads the article at that revision and
# highlights the claims harvested from it) and the count of harvested claims.
if @assignment
  json.assignment { json.partial! 'assignment', assignment: @assignment }
else
  json.assignment nil
end

json.articles @tiles do |tile|
  article = tile.article
  json.id article.id
  json.mw_rev_id tile.mw_rev_id
  json.mw_rev_timestamp tile.mw_rev_timestamp
  json.claim_count tile.claim_count
  json.title article.full_title
  json.language article.wiki.language
  json.project article.wiki.project
  json.url article.url
  json.mw_page_id article.mw_page_id
end
