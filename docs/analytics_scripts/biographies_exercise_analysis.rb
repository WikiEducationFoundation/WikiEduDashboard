# Find out which articles from among the biography lists
# were edited by students in Spring 2025 courses
# 
# https://en.wikipedia.org/wiki/Wikipedia:Wiki_Education/Biographies
# https://dashboard.wikiedu.org/training/students/update-a-biography-exercise/find-a-bio-to-improve
# 

en_wiki = Wiki.get_or_create(language: 'en', project: 'wikipedia')

# the two wikidata lists, based on linked-from
# https://petscan.wmcloud.org/?psid=32906495

wikidata_cat = Category.get_or_create(wiki: en_wiki, name: 32906495, depth: 0, source: 'psid' )
wikidata_cat.refresh_titles # 2919 titles

# https://en.wikipedia.org/wiki/Category:21st-century_African-American_scientists 
# depth 1 to include physicians subcat
# https://petscan.wmcloud.org/?psid=32906514 
#

aa_scientists_cat = Category.get_or_create(wiki: en_wiki, name: 32906514, depth: 0, source: 'psid' )
aa_scientists_cat.refresh_titles # 507 titles

# https://en.wikipedia.org/wiki/Category:Hispanic_and_Latino_American_scientists
# Depth 6 (count stops increasing at depth 4) to include the various subcats
# https://petscan.wmcloud.org/?psid=32906566
#

hla_scientists_cat = Category.get_or_create(wiki: en_wiki, name: 32906566, depth: 0, source: 'psid' )
hla_scientists_cat.refresh_titles # 271 titles

exercise_biographies = wikidata_cat.article_titles + aa_scientists_cat.article_titles + hla_scientists_cat.article_titles

bio_article_ids = Article.where(title: exercise_biographies, namespace: 0, wiki_id: 1).pluck(&:id)

spring_2025 = Campaign.find_by_slug 'spring_2025'
spring_2025_ac = ArticlesCourses.where(course: spring_2025.courses, article_id: bio_article_ids)


CSV.open("/home/sage/broadcom_bios.csv", 'wb') do |csv|
  csv << %w[article_title course student references_added]
  spring_2025_ac.each do |ac|
    # Including just the first student who edited each one is good enough.
    student = ac.user_ids.first && User.find(ac.user_ids.first)
    csv << [ac.article.title, ac.course.slug, student&.username, ac.references_count]
  end
end
