#= Helpers for course views
module CourseHelper
  def find_course_by_slug(slug)
    course = Course.find_by_slug(slug)
    if course.nil?
      fail ActionController::RoutingError.new('Not Found'), 'Course not found'
    end
    return course
  end

  def current?(course)
    course.current?
  end

  def pretty_course_title(course)
    "#{course.school} - #{course.title} (#{course.term})"
  end

  def word_count_from_character_sum(character_sum)
    # Aaron Halfaker has done some analysis on the relationship between
    # byte length and visible characters in English Wikipedi articles.
    # According to his regression, the ratio is 1.15 bytes per visible character.
    # Combining that with standard English ratio of 4.5 letters per word, and
    # we get 5.175 characters / word.
    # See discussion here: https://lists.wikimedia.org/pipermail/wiki-research-l/2013-August/002999.html
    # See graph with regression line here: https://commons.wikimedia.org/wiki/File:Bytes.content_length.scatter.correlation.enwiki.png
    # This is just a rough estimate, pending research on how bytes *added*
    # relates to changes in readable word count for work by student editors.
    character_sum / 5.175
  end
end
