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

  def format_wikidata_stats(course_stats)
    course_stats['www.wikidata.org']['other updates'] += course_stats['www.wikidata.org']['unknown']
    course_stats['www.wikidata.org'].reject! { |k, _v| k == 'unknown' }
    course_stats.each_value do |stat|
      stat.each do |key, value|
        stat[key] = number_to_human(value)
      end
    end
    course_stats
  end
end
