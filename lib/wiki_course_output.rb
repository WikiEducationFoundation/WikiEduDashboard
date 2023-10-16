# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wikitext"
require_dependency "#{Rails.root}/lib/course_meetings_manager"
require_dependency "#{Rails.root}/lib/wiki_output_templates"

#= Class for generating wikitext from course information.
class WikiCourseOutput
  include WikiOutputTemplates

  def initialize(course)
    @course = course
    @course_meetings_manager = @course.meetings_manager
    @dashboard_url = ENV['dashboard_url']
    @first_instructor_course_user = @course
                                    .courses_users
                                    .where(role: CoursesUsers::Roles::INSTRUCTOR_ROLE).first
    @first_instructor = @first_instructor_course_user&.user
    @first_support_staff = @course.nonstudents.where(greeter: true).first
    @output = ''
    @templates = @course.home_wiki.edit_templates
  end

  ###############
  # Entry point #
  ###############
  def translate_course_to_wikitext
    # Course description and details
    @output += course_details_and_description

    # Table of students, assigned articles, and reviews
    @output += students_table

    @output
  end

  #####################
  # Output components #
  #####################

  private

  def course_details_and_description
    description = Wikitext.markdown_to_mediawiki(@course.description)
    course_details + "\r" + description
  end

  def course_details
    # TODO: add support for multiple instructors, multiple content experts.
    # TODO: switch this to a new template specifically for dashboard courses.
    <<~COURSE_DETAILS
      {{#{template_name(@templates, 'course')}
       | course_name = #{@course.title}
       | instructor_username = #{instructor_username}
       | instructor_realname = #{instructor_realname}
       | support_staff = #{support_staff_username}
       | subject = #{@course.subject}
       | start_date = #{@course.start}
       | end_date = #{@course.end}
       | institution = #{@course.school}
       | expected_students = #{@course.expected_students}
       | assignment_page = #{@course.wiki_title}
       | slug = #{@course.slug}
       | campaigns = #{@course.campaigns.pluck(:title).join(', ')}
       | #{@dashboard_url} = yes
      }}
    COURSE_DETAILS
  end

  def instructor_username
    @first_instructor&.username
  end

  def instructor_realname
    @first_instructor_course_user&.real_name
  end

  def support_staff_username
    @first_support_staff&.username
  end

  def students_table
    students = @course.students
    return '' if students.blank?
    table = "{{#{template_name(@templates, 'table')}}}\r"
    students.each do |student|
      table += student_row(student)
    end
    table += "{{#{template_name(@templates, 'table_end')}}}\r"
    table
  end

  def student_row(student)
    username = student.username
    assignments = student.assignments.where(course_id: @course.id)
    assigned = Wikitext.assignments_to_wikilinks(assignments.assigned, @course.home_wiki)
    reviewing = Wikitext.assignments_to_wikilinks(assignments.reviewing, @course.home_wiki)

    "{{#{template_name(@templates, 'table_row')}|#{username}|#{assigned}|#{reviewing}}}\r"
  end
end
