# frozen_string_literal: true
require_dependency Rails.root.join('lib/wiki_output_templates')

#= Class for generating wikitext for updating a userpage
class WikiUserpageOutput
  include WikiOutputTemplates

  def initialize(course)
    @course = course
    @templates = @course.home_wiki.edit_templates
  end

  def enrollment_template
    "{{#{template_name(@templates, 'editor')}"\
      "#{course_page_param}"\
      "#{course_slug_param}"\
      "#{course_type_param}"\
      ' }}'
  end

  def enrollment_summary
    case @course.type
    when 'FellowsCohort'
      "User is participating in #{@course.slug}."
    else
      "User has enrolled in [[#{@course.wiki_title}]]."
    end
  end

  def enrollment_talk_template
    "{{#{template_name(@templates, 'user_talk')}"\
      "#{course_page_param}"\
      "#{course_slug_param}"\
      "#{course_type_param}"\
      ' }}'
  end

  def sandbox_template(dashboard_url)
    "{{#{dashboard_url} sandbox#{course_type_param}}}"
  end

  def disenrollment_summary
    case @course.type
    when 'FellowsCohort'
      "User is no longer participating in #{@course.slug}."
    else
      "User has disenrolled in [[#{@course.wiki_title}]]."
    end
  end

  private

  def course_page_param
    return unless @course.wiki_title
    " | course = [[#{@course.wiki_title}]]"
  end

  def course_slug_param
    " | slug = #{@course.slug}"
  end

  def course_type_param
    return unless @course.wiki_template_param
    " | type = #{@course.wiki_template_param}"
  end
end
