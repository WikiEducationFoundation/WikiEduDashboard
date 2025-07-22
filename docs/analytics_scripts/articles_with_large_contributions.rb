# This is a script to pull a list of articles edited in a specific term that
# had a substantial amount of content added, so that we can do manual research on them.

require 'csv'

arts = Campaign.find_by_slug('spring_2023').articles_courses.to_a

# at least 500 words added, estimated by character_sum
arts_500 = arts_500 = arts.filter { |a| a.character_sum > (500*5.175) }

#random order so we can sample them easily
arts_500.shuffle!

CSV.open("/home/sage/spring_2023_arts.csv", 'wb') do |csv|
  csv << %w[article_title characters_added new_article article_id course_slug]
  arts_500.each do |ac|
    csv << [ac.article.title, ac.character_sum, ac.new_article, ac.article_id, ac.course.slug]
  end
end
