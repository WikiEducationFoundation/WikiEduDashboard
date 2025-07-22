# frozen_string_literal: true

json.course do
  json.revisions @revisions do |revision|
    json.call(revision, :id, :characters, :views, :date, :url,
              :user_id, :mw_rev_id, :mw_page_id, :wiki)
    json.references_added revision.references_added
    json.article do
      if revision.article.nil?
        json.title 'Deleted article'
        json.url nil
        json.namespace nil
      else
        json.title revision.article.full_title
        json.url revision.article.url
        json.namespace revision.article.namespace
      end
    end
  end
end
