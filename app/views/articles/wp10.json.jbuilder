# frozen_string_literal: true
i = 0
json.array! @article.revisions.each do |revision|
  i += 1
  json.index i
  json.rev_id revision.mw_rev_id
  json.wp10 revision.wp10
  json.date revision.date
  json.username revision.user.username
end
