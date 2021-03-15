# This find records that violate the constraint of only one non-deleted article mw_page_id per wiki.
# It deletes the ones that don't have any other records associated with them.
# The remaining duplicates will need to be investigated further.
duplicate_counts = Article.where(deleted: false).group(:mw_page_id, :wiki_id).having('count(*) > 1').count
# duplicate_counts keys are like [mw_page_id, wiki_id]

duplicate_counts.keys.each do |key|
  mw_page_id = key[0]
  wiki_id = key[1]
  articles = Article.where(mw_page_id: mw_page_id, wiki_id: wiki_id, deleted: false)
  articles.each do |art|
    puts art.id
    puts art.title
    next if art.assignments.any?
    next if art.revisions.any?
    next if art.articles_courses.any?
    puts 'No records!'
    art.destroy
  end
end

# After that, we're left only with cases of 2 articles.

duplicate_counts = Article.where(deleted: false).group(:mw_page_id, :wiki_id).having('count(*) > 1').count

# In this pass, we first cases where one article has revisions, another has assignments but no revisions
duplicate_counts.keys.each do |key|
  # first, update article status to make sure we have the correct page name. many of the duplicates have related but different names
  wiki = Wiki.find key[1]
  ArticleStatusManager.new(wiki).update_status(Article.where(mw_page_id: key[0], wiki_id: key[1]))
  # Now update any assignments to point to the record that has revisions
  arts = Article.where(mw_page_id: key[0], wiki_id: key[1], deleted: false)

  if arts.count > 2
    puts 'too many articles'
    next
  end

  art_with_revisions = nil
  art_with_assignments = nil
  arts.each do |art|
    puts art.title
    if art.revisions.any?
      art_with_revisions = art
    elsif art.assignments.any?
      art_with_assignments = art
    end
  end

  if art_with_assignments.nil?
    puts 'no assignments'
    next
  end

  if art_with_revisions.nil?
    puts 'no revisions'
    next
  end

  if art_with_assignments.id == art_with_revisions.id
    puts 'same article with revs and assignments'
    next
  end

  if art_with_assignments.title != art_with_revisions.title
    puts 'titles do not match!'
    next
  end

  art_with_assignments.assignments.each do |ass|
    ass.update(article_id: art_with_revisions.id)
    puts 'updated assignment'
  end
end

# Now run the first script again to delete more records

# Now we take care of cases where there are no revisions, and assignments are split between records
duplicate_counts = Article.where(deleted: false).group(:mw_page_id, :wiki_id).having('count(*) > 1').count
duplicate_counts.keys.each do |key|
  # Now update any assignments to point to the record that has revisions
  arts = Article.where(mw_page_id: key[0], wiki_id: key[1], deleted: false)

  if arts.count > 2
    puts 'too many articles'
    next
  end

  unexpected_revs = false
  arts.each do |art|
    if art.revisions.any?
      puts 'unexpected revisions!'
      unexpected_revs = true
    end
  end
  next if unexpected_revs

  if arts.first.title != arts.second.title
    puts 'titles do not match!'
    next
  end

  arts.second.assignments.each do |ass|
    ass.update(article_id: arts.first.id)
    puts 'assignment updated!'
  end
end

# Now run the first script again to delete articles

# We also have cases where the title is wrong because of namespace reasons
