# frozen_string_literal: true

json.revisions @revisions.includes(:article, :user) do |rev|
  json.call(rev, :url, :user_id, :mw_rev_id, :mw_page_id, :wiki)
  json.key rev.id
  json.datetime rev.date
  json.article_url rev.article.url
  json.title rev.article.full_title
  json.references_added rev.references_added
  json.username rev.user.username
  json.report_url @show_report ? nil : rev.plagiarism_report_link
  json.courses [@course]
end
