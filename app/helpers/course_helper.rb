# frozen_string_literal: true

#= Helpers for course views
module CourseHelper
  def find_course_by_slug(slug)
    course = Course.find_by(slug: slug)
    raise ActionController::RoutingError.new('Not Found'), "Course #{slug} not found" if course.nil?
    return course
  end

  def pretty_course_title(course)
    "#{course.school} - #{course.title} (#{course.term})"
  end

  def date_highlight_class(course)
    return 'table-row--warning' if 1.week.from_now > course.end
    return 'table-row--info' if course.start > 1.week.ago
    return ''
  end

  def private_highlight_class(course)
    return 'table-row--danger' if course.private
    return ''
  end

  def course_i18n(message_key, course = nil)
    string_prefix = course&.string_prefix
    string_prefix ||= Features.default_course_string_prefix
    I18n.t("#{string_prefix}.#{message_key}")
  end

  def format_course_stats(course_stats)
    course_stats.each do |wiki_ns_key, wiki_ns_stats|
      if wiki_ns_key == 'www.wikidata.org'
        course_stats[wiki_ns_key]['other updates'] += course_stats[wiki_ns_key]['unknown']
        course_stats[wiki_ns_key].reject! { |k, _v| k == 'unknown' }
      end
      # convert stats to human readable values
      course_stats[wiki_ns_key].each do |stat_key, stat|
        course_stats[wiki_ns_key][stat_key] = number_to_human(stat)
      end
    end
    course_stats
  end
end
