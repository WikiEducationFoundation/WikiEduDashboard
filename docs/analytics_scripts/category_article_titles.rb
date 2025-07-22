# Dump the titles from a Category record into a CSV

require 'csv'

cat_id = 874

CSV.open('/home/ragesoss/cat_titles.csv', 'wb') do |csv|
  cat = Category.find(cat_id)

  cat.article_titles.each do |title|
    csv << [title]
  end
end