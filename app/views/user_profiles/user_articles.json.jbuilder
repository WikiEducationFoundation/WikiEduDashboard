# frozen_string_literal: true

# Group articles by course for UserDetails component
articles_by_course = @user_articles.group_by(&:course_id)

json.articles_by_course articles_by_course.map do |_course_id, article_courses|
  course = article_courses.first.course

  articles_data = article_courses.map do |article_course|
    stats = @user_article_stats[[article_course.course_id, article_course.article_id]]
    if stats
      char_sum = stats[:character_sum]
      refs_count = stats[:references_count]
      is_new = stats[:new_article]
    elsif @courses_with_acuwt.include?(article_course.course_id)
      char_sum = 0
      refs_count = 0
      is_new = false
    else
      char_sum = article_course.character_sum.to_i
      refs_count = article_course.references_count.to_i
      is_new = article_course.new_article
    end

    article = article_course.article
    {
      article_id: article.id,
      title: article.title,
      url: article.url,
      word_count: WordCount.from_characters(char_sum),
      character_sum: char_sum,
      references_count: refs_count,
      new_article: is_new,
      language: article.language,
      project: article.wiki&.project,
      wiki_language: article.wiki&.language
    }
  end

  articles_data.sort_by! { |a| -a[:character_sum] }
  course_char_sum = articles_data.sum { |a| a[:character_sum] }
  course_refs_count = articles_data.sum { |a| a[:references_count] }

  json.course_id course.id
  json.course_title course.title
  json.course_slug course.slug

  # Calculate totals for this course from user's contributions
  json.word_count WordCount.from_characters(course_char_sum)
  json.references_count course_refs_count
  json.articles_edited articles_data.count

  json.articles articles_data do |article_data|
    json.article_id article_data[:article_id]
    json.title article_data[:title]
    json.url article_data[:url]
    json.word_count article_data[:word_count]
    json.references_count article_data[:references_count]
    json.new_article article_data[:new_article]
    json.language article_data[:language]
    json.project article_data[:project]
    json.wiki_language article_data[:wiki_language]
  end
end