# frozen_string_literal: true

# Data cleanup for Revisions to remove duplicates that match mw_rev_id and wiki_id
# in preparation for adding a unique index for those attributes.

dups = Revision.all.group(:wiki_id, :mw_rev_id).having('count(*) > 1').count

def revs_match(rev, good_rev)
  return false unless rev.wiki_id == good_rev.wiki_id
  return false unless rev.mw_rev_id == good_rev.mw_rev_id
  return false unless rev.article_id == good_rev.article_id
  return false unless rev.mw_page_id == good_rev.mw_page_id
  return false unless rev.user_id == good_rev.user_id
  true
end

dups.each do |attributes, count|
  revs = Revision.where(wiki_id: attributes[0], mw_rev_id: attributes[1])
  raise unless revs.count == count
  good_rev = revs.first
  bad_revs = revs - [good_rev]
  raise unless bad_revs.size == count - 1
  bad_revs.each do |rev|
    unless revs_match(rev, good_rev)
      pp rev.mw_rev_id
      next
    end
    rev.destroy
  end
end

dups = Revision.all.group(:wiki_id, :mw_rev_id).having('count(*) > 1').count

dups.each do |attributes, count|
  revs = Revision.where(wiki_id: attributes[0], mw_rev_id: attributes[1])
  raise unless revs.count == count
  good_rev = revs.first
  bad_revs = revs - [good_rev]
  raise unless bad_revs.size == count - 1
  bad_revs.each do |rev|
    if rev.article.deleted
      rev.destroy
    else
      pp rev
    end
  end
end
