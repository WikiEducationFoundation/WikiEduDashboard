# This script is for exploring the question of how AI usage by students
# has changed over time, by collecting comparable samples of student articles
# from different terms.

# The simplest way to begin is to look at new articles.
# ChatGPT was released in November 2022. We'll start a few terms
# before to establlish a baseline where we can assume no LLM usage.


# On production server, get a CSV of new articles by term

terms = %w[spring_2018 fall_2018 spring_2019 fall_2019
           spring_2020 fall_2020 spring_2021 fall_2021
           spring_2022 fall_2022 spring_2023 fall_2023
           spring_2024 fall_2024 spring_2025]

campaigns = terms.map { |term| Campaign.find_by_slug term }

def new_articles_from_campaign(campaign)
  campaign.articles_courses.where(new_article: true)
end

EN_WIKI = Wiki.get_or_create(language: 'en', project: 'wikipedia')

headers = %w[title namespace mw_page_id deleted campaign course course_end_date first_student_editor]
articles_to_analyze = [headers]

campaigns.each do |campaign|
  puts campaign.slug

  new_articles_from_campaign(campaign).each do |ac|
    # Skip deleted articles and non-en.wiki articles
    next if ac.article.deleted
    next unless ac.article.wiki_id == EN_WIKI.id

    article_data = [
      ac.article.title,
      ac.article.namespace,
      ac.article.mw_page_id,
      ac.article.deleted,
      campaign.slug,
      ac.course.slug,
      ac.course.end,
      User.find_by(id: ac.user_ids.first)&.username,
    ]
    articles_to_analyze << article_data
  end
end

CSV.open("/home/sage/new_articles_by_term.csv", 'wb') do |csv|
  articles_to_analyze.each { |line| csv << line }
end

