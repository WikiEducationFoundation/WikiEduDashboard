require "#{Rails.root}/lib/wikitext"
require "#{Rails.root}/lib/course_meetings_manager"

#= Class for generating wikitext from course information.
class WikiCourseOutput
  def initialize(course)
    @course = course
    @course_meetings_manager = CourseMeetingsManager.new(@course)
    @first_instructor = @course.instructors.first
    @first_support_staff = @course.nonstudents.where(greeter: true).first
    @output = ''
  end

  ###############
  # Entry point #
  ###############
  def translate_course_to_wikitext
    # Course description and details
    @output += course_details_and_description

    # Table of students, assigned articles, and reviews
    @output += students_table

    # Timeline
    @output += "{{start of course timeline}}\r"
    week_count = 0
    @course.weeks.each do |week|
      week_count += 1
      week_number = week_count
      @output += course_week(week, week_number)
    end

    # TODO: grading
    @output
  end

  #####################
  # Output components #
  #####################

  def course_details_and_description
    description = Wikitext.markdown_to_mediawiki(@course.description)
    course_details + "\r" + description
  end

  def course_details
    # TODO: add support for multiple instructors, multiple content experts.
    # TODO: switch this to a new template specifically for dashboard courses.
    "{{course details
     | course_name = #{@course.title}
     | instructor_username = #{instructor_username}
     | instructor_realname = #{instructor_realname}
     | support_staff = #{support_staff_username}
     | subject = #{@course.subject}
     | start_date = #{@course.start}
     | end_date = #{@course.end}
     | institution = #{@course.school}
     | expected_students = #{@course.expected_students}
     | assignment_page = #{course_prefix}/#{@course.slug}
     | #{dashboard_url} = yes
    }}"
  end

  def instructor_username
    @first_instructor.username unless @first_instructor.nil?
  end

  def instructor_realname
    @first_instructor.real_name unless @first_instructor.nil?
  end

  def support_staff_username
    @first_support_staff.username unless @first_support_staff.nil?
  end

  def course_prefix
    ENV['course_prefix']
  end

  def dashboard_url
    ENV['dashboard_url']
  end

  def course_week(week, week_number)
    week_output = week_header(week, week_number)

    ordered_blocks = week.blocks.order(:order)
    ordered_blocks.each do |block|
      week_output += content_block(block)
    end

    week_output += "{{end of course week}}\r"
    week_output
  end

  def week_header(week, week_number)
    header_output = "=== Week #{week_number} ===\r"

    header_output += '{{start of course week'
    meeting_dates = @course_meetings_manager.meeting_dates_of(week).map(&:to_s)
    header_output += '|' + meeting_dates.join('|') unless meeting_dates.blank?
    header_output += "}}\r"
    header_output
  end

  def content_block(block)
    block_types = ['in class|In class - ',
                   'assignment|Assignment - ',
                   'assignment milestones|',
                   'assignment|'] # TODO: get the custom value
    block_type = block_types[block.kind]
    block_output = "{{#{block_type}#{block.title}}}\r"
    block_output += Wikitext.html_to_mediawiki(block.content)
    block_output
  end

  def students_table
    students = @course.students
    return '' if students.blank?
    table = "{{students table}}\r"
    students.each do |student|
      table += student_row(student)
    end
    table += "{{end of students table}}\r"
    table
  end

  def student_row(student)
    username = student.username
    assignments = student.assignments.where(course_id: @course.id)
    assigned_titles = assignments.assigned.pluck(:article_title)
    assigned = Wikitext.titles_to_wikilinks(assigned_titles)
    reviewing_titles = assignments.reviewing.pluck(:article_title)
    reviewing = Wikitext.titles_to_wikilinks(reviewing_titles)

    "{{student table row|#{username}|#{assigned}|#{reviewing}}}\r"
  end
end
