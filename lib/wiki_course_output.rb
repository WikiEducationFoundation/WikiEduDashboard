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
    @all_instructor_course_users = @course
                                   .courses_users
                                   .where(role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    @first_instructor_course_user = @all_instructor_course_users.first
    @first_instructor = @first_instructor_course_user&.user
    @all_instructors = @all_instructor_course_users.map(&:user)
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

  def course_details # rubocop:disable Metrics/MethodLength
    # TODO: add support for multiple content experts.
    # TODO: switch this to a new template specifically for dashboard courses.

    # Example output with multiple instructors
    # {{program details
    #  | course_name = Advanced Legal Research Winter 2020
    #  | instructor_username = Tlmarks
    #  | instructor_realname =
    #  | instructor_username_2 = Shelbaum
    #  | instructor_username_3 = Abishekdascs
    #  | instructor_username_4 = Abishek CS Das
    #  | support_staff =
    #  | subject = Legal Research
    #  | start_date = 2024-02-01 00:00:00 UTC
    #  | end_date = 2024-09-13 23:59:59 UTC
    #  | institution = Stanford Law School
    #  | expected_students =
    #  | assignment_page =
    #  | slug = Stanford_Law_School/Advanced_Legal_Research_Winter_2020_(Winter)
    #  | campaigns = Default Campaign
    #  | outreachdashboard.wmflabs.org = yes
    # }}

    details = <<~COURSE_DETAILS
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

    insert_additional_instructors(details) if @all_instructors.size > 1

    details
  end

  def instructor_username
    @first_instructor&.username
  end

  def instructor_realname
    @first_instructor_course_user&.real_name
  end

  def insert_additional_instructors(details)
    # Collect additional instructor usernames and insert them after the first instructor
    additional_instructors = @all_instructors[1..].map.with_index(2) do |instructor, index|
      " | instructor_username_#{index} = #{instructor.username}\n"
    end.join

    # Insert additional instructors immediately after the first instructor's real name
    insertion_point = details.index("| instructor_realname = #{instructor_realname}") +
                      "| instructor_realname = #{instructor_realname}".length

    details.insert(insertion_point, additional_instructors)
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
