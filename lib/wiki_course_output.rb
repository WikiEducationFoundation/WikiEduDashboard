require 'pandoc-ruby'
require "#{Rails.root}/lib/course_meetings_manager"

#= Class for generating wikitext from course information.
class WikiCourseOutput
  ################
  # Entry points #
  ################
  def self.translate_course(course)
    course_meetings_manager = CourseMeetingsManager.new(course)

    # Course description and details
    output = course_details_and_description(course)

    # Table of students, assigned articles, and reviews
    output += students_table(course)

    # Timeline
    output += "{{start of course timeline}}\r"
    week_count = 0
    course.weeks.each do |week|
      week_count += 1
      week_number = week_count
      output += course_week(week, week_number, course_meetings_manager)
    end

    # TODO: grading
    output
  end

  #####################
  # Output components #
  #####################
  def self.course_details_and_description(course)
    # TODO: add support for multiple instructors, multiple content experts.
    # TODO: switch this to a new template specifically for dashboard courses.
    instructor = course.instructors.first
    support_staff = course.nonstudents.where(greeter: true).first
    course_prefix = ENV['course_prefix']
    dashboard_url = ENV['dashboard_url']
    course_details = "{{course details
     | course_name = #{course.title}
     | instructor_username = #{instructor.wiki_id unless instructor.nil?}
     | instructor_realname = #{instructor.real_name unless instructor.nil?}
     | support_staff = #{support_staff.wiki_id unless support_staff.nil?}
     | subject = #{course.subject}
     | start_date = #{course.start}
     | end_date = #{course.end}
     | institution = #{course.school}
     | expected_students = #{course.expected_students}
     | assignment_page = #{course_prefix}/#{course.slug}
     | #{dashboard_url} = yes
    }}"
    description = markdown_to_mediawiki("#{course.description}")
    course_details + "\r" + description
  end

  def self.course_week(week, week_number, course_meetings_manager)
    block_types = ['in class|In class - ',
                   'assignment|Assignment - ',
                   'assignment milestones|',
                   'assignment|'] # TODO: get the custom value
    week_output = "=== Week #{week_number} ===\r"

    week_output += '{{start of course week'
    meeting_dates = course_meetings_manager.meeting_dates_of(week).map(&:to_s)
    week_output += '|' + meeting_dates.join('|') unless meeting_dates.blank?
    week_output += "}}\r"

    ordered_blocks = week.blocks.order(:order)
    ordered_blocks.each do |block|
      block_type = block_types[block.kind]
      week_output += "{{#{block_type}#{block.title}}}\r"
      week_output += html_to_mediawiki("#{block.content}")
    end
    week_output += "{{end of course week}}\r"
    week_output
  end

  def self.students_table(course)
    students = course.students
    return '' if students.blank?
    table = "{{students table}}\r"
    students.each do |student|
      username = student.wiki_id
      assignments = student.assignments.where(course_id: course.id)
      assigned_titles = assignments.assigned.pluck(:article_title)
      assigned = titles_to_wikilinks assigned_titles
      reviewing_titles = assignments.reviewing.pluck(:article_title)
      reviewing = titles_to_wikilinks reviewing_titles
      table += "{{student table row|#{username}|#{assigned}|#{reviewing}}}\r"
    end
    table += "{{end of students table}}\r"
    table
  end

  ################################
  # wikitext formatting methods #
  ################################
  def self.markdown_to_mediawiki(item)
    wikitext = PandocRuby.convert(item, from: :markdown, to: :mediawiki)
    wikitext = replace_code_with_nowiki(wikitext)
    wikitext = reformat_image_links(wikitext)
    wikitext = replace_at_sign_with_template(wikitext)
    wikitext
  end

  def self.html_to_mediawiki(item)
    wikitext = PandocRuby.convert(item, from: :html, to: :mediawiki)
    wikitext = replace_code_with_nowiki(wikitext)
    wikitext = replace_at_sign_with_template(wikitext)
    wikitext = reformat_links(wikitext)
    wikitext
  end

  # Replace instances of <code></code> with <nowiki></nowiki>
  # This lets us use backticks to format blocks of mediawiki code that we don't
  # want to be parsed in the on-wiki version of a course page.
  def self.replace_code_with_nowiki(text)
    if text.include? '<code>'
      text = text.gsub('<code>', '<nowiki>')
      text = text.gsub('</code>', '</nowiki>')
    end
    text
  end

  # Replace instances of @ with an image-based template equivalent.
  # This prevents email addresses from triggering a spam warning.
  def self.replace_at_sign_with_template(text)
    text = text.gsub('@', '{{@}}')
    text
  end

  def self.titles_to_wikilinks(titles)
    return '' if titles.blank?
    titles_with_spaces = titles.map { |t| t.tr('_', ' ') }
    wikitext = '[[' + titles_with_spaces.join(']], [[') + ']]'
    wikitext
  end

  # Fix full urls that have been formatted like wikilinks.
  # [["https://foo.com"|Foo]] -> [https://foo.com Foo]
  def self.reformat_links(text)
    text = text.gsub(/\[\["(http.*?)"\|(.*?)\]\]/, '[\1 \2]')
    text
  end

  # Take file links that come out of Pandoc and attempt to create valid wiki
  # image code for them. This method assumes a recent version of Pandoc that
  # uses "File:" rather than "Image:" as the MediaWiki file prefix.
  def self.reformat_image_links(text)
    # Clean up file URLS
    # TODO: Fence this, ensure usage of wikimedia commons?

    # Get an array of [[File: ...]] and [[Image: ...]] tags from the content
    file_tags = text.scan(/\[\[[File:|Image:][^\]]*\]\]/)
    file_tags.each do |file_tag|
      # Remove the absolute portion of the file's URL
      fixed_tag = file_tag.gsub(%r{(?<=File:|Image:)[^\]]*/}, '')
      text.gsub! file_tag, fixed_tag
    end
    text
  end

  def self.substitute_bad_links(text, links)
    links.each do |link|
      safe_link = link.gsub('.', '(.)')
      text = text.gsub(link, safe_link)
    end
    text
  end
end
