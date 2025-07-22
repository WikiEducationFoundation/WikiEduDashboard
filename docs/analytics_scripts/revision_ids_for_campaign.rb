
campaign = Campaign.find_by_slug('spring_2018')

revisions = []
deleted_revisions = []

campaign.courses.each do |course|
  deleted_revisions += course.revisions.where(deleted: true).joins(:article).where(articles: { namespace: 0 }).pluck(:mw_rev_id)
end

revisions = revisions.uniq
deleted_revisions = deleted_revisions.uniq
deleted_revisions.count

IO.write "/home/sage/#{campaign.slug}_revs.csv", revisions.join("\n")
