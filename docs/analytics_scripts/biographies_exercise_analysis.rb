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
wikidata_cat.refresh_titles # 2919 titles in March; 2924 in April; 2932 in June

# https://en.wikipedia.org/wiki/Category:21st-century_African-American_scientists 
# depth 1 to include physicians subcat
# https://petscan.wmcloud.org/?psid=32906514 
#

aa_scientists_cat = Category.get_or_create(wiki: en_wiki, name: 32906514, depth: 0, source: 'psid' )
aa_scientists_cat.refresh_titles # 507 titles in March, 508 in April, 509 in June

# https://en.wikipedia.org/wiki/Category:Hispanic_and_Latino_American_scientists
# Depth 6 (count stops increasing at depth 4) to include the various subcats
# https://petscan.wmcloud.org/?psid=32906566
#

hla_scientists_cat = Category.get_or_create(wiki: en_wiki, name: 32906566, depth: 0, source: 'psid' )
hla_scientists_cat.refresh_titles # 271 titles in March and April; 275 in June

exercise_biographies = wikidata_cat.article_titles + aa_scientists_cat.article_titles + hla_scientists_cat.article_titles

bio_article_ids = Article.where(title: exercise_biographies, namespace: 0, wiki_id: 1).map(&:id)
# 1667 ids in April; 1678 in June

spring_2025 = Campaign.find_by_slug 'spring_2025'
spring_2025_ac = ArticlesCourses.where(course: spring_2025.courses, article_id: bio_article_ids)
# 464 in March, 630 in April, 666 in June


CSV.open("/home/sage/broadcom_bios_june_13.csv", 'wb') do |csv|
  csv << %w[article_title course student references_added bytes_added from_wikidata_list from_aa_scientists_cat from_hla_scientists_cat]
  spring_2025_ac.each do |ac|
    title = ac.article.title
    puts title
    # Including just the first student who edited each one is good enough.
    student = ac.user_ids.first && User.find(ac.user_ids.first)
    csv << [title, ac.course.slug, student&.username, ac.references_count, ac.character_sum, wikidata_cat.article_titles.include?(title), aa_scientists_cat.article_titles.include?(title), hla_scientists_cat.article_titles.include?(title)]
  end
end
