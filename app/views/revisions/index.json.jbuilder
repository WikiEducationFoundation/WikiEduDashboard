# frozen_string_literal: true
json.course do
  json.revisions @revisions do |revision|
    json.call(revision, :id, :characters, :views, :date, :url, :user_id, :mw_rev_id, :mw_page_id, :wiki)
    json.article do
      if revision.article.nil?
        json.title 'Deleted article'
        json.url nil
      else
        json.title full_title(revision.article)
        json.url article_url(revision.article)
      end
    end
  end
end
