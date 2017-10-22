# frozen_string_literal: true

json.article_details do
  json.first_revision do
    json.call(@first_revision, :wiki, :mw_rev_id, :mw_page_id) if @first_revision
  end

  json.last_revision do
    json.call(@last_revision, :wiki, :mw_rev_id, :mw_page_id) if @last_revision
  end

  json.editors do
    json.array! @editors.map(&:username)
  end
end
