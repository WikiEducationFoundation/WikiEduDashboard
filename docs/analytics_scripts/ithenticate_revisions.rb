# Get the essential data about revisions flagged by the copyvio detection system
# since it can't be recreated if the revisions table is cleared.

Revision.where.not(ithenticate_id: nil).count

CSV.open('/home/sage/ithenticate_revisions.csv', 'wb') do |csv|
  csv << ['mw_rev_id', 'ithenticate_id', 'wiki', 'article_title']
  Revision.where.not(ithenticate_id: nil).each do |rev|
    csv << [rev.mw_rev_id, rev.ithenticate_id, rev.wiki.domain, rev.article.title]
  end
end