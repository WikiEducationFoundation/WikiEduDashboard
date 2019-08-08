# This replicates analysis LiAnna used to run on Wikimetrics, showing the total content progress as of the 15th and 30th of each month for each term.

campaign = Campaign.find_by_slug('spring_2019')
year = 2019

revision_ids = []
campaign.courses.each do |course|
  revision_ids += course.all_revisions.joins(:article).where(articles: { namespace: Article::Namespaces::MAINSPACE }).pluck(:id)
end

def first_date(month, year)
  padding = month < 10 ? '0' : ''
  "#{year}-#{padding}#{month}-16".to_date
end

def second_date(month, year)
  padding = month < 9 ? '0' : ''
  if month == 12
    "#{year + 1}-01-01".to_date
  else
    "#{year}-#{padding}#{month+1}-01".to_date
  end
end

(1..12).each do |month|
  pp first_date(month, year), Revision.where(id: revision_ids).where('date < ?', first_date(month, year)).where('characters >= 0').sum(:characters)
  pp second_date(month, year), Revision.where(id: revision_ids).where('date < ?', second_date(month, year)).where('characters >= 0').sum(:characters)
end

