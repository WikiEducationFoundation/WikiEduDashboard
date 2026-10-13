# frozen_string_literal: true

# Group articles by course for UserDetails component
articles_by_course = @user_articles.group_by(&:course_id)

json.articles_by_course articles_by_course.map do |course_id, article_courses|
  course = article_courses.first.course
  total_character_sum = article_courses.sum(&:character_sum).to_i

  json.course_id course.id
  json.course_title course.title
  json.course_slug course.slug

  # Calculate totals for this course
  json.word_count WordCount.from_characters(total_character_sum)
  json.references_count article_courses.sum(&:references_count).to_i
  json.articles_edited article_courses.count

  # Get articles for this course
  json.articles article_courses.map do |article_course|
    article = article_course.article

    json.article_id article.id
    json.title article.title
    json.url article.url
    json.word_count WordCount.from_characters(article_course.character_sum).to_i
    json.references_count article_course.references_count.to_i
    json.new_article article_course.new_article
    json.language article.language
    json.project article.wiki&.project
    json.wiki_language article.wiki&.language
  end
end

json.total_count @user_articles.count
json.filtered_by_course @course_id.present?