require 'pandoc-ruby'

#= Class for generating wikitext from course information
class WikiOutput
  ################
  # Entry points #
  ################
  def self.translate_course(course, _current_user)
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
      output += course_week(week, week_number)
    end

    # TODO: grading

    output = replace_code_with_nowiki(output)
    output
  end

  #####################
  # Output components #
  #####################
  def self.course_details_and_description(course)
    # TODO: add support for multiple instructors
    instructor = course.instructors.first
    course_prefix = Figaro.env.course_prefix
    course_details = "{{course details
     | course_name = #{course.title}
     | instructor_username = #{instructor.wiki_id unless instructor.nil?}
     | instructor_realname = #{instructor.wiki_id unless instructor.nil?}
     | subject = #{course.subject}
     | start_date = #{course.start}
     | end_date = #{course.end}
     | institution =  #{course.school}
     | expected_students = #{course.user_count}
     | assignment_page = #{course_prefix}/#{course.slug}
     | wikiedu.org = yes
    }}"
    description = markdown_to_mediawiki("#{course.description}")
    course_details + "\r" + description
  end

  def self.course_week(week, week_number)
    block_types = ['in class|In class - ',
                   'assignment|Assignment - ',
                   'assignment milestones|',
                   'assignment|'] # TODO: get the custom value
    if week.title? && week.title != ''
      week_output = "=== Week #{week_number}: #{week.title} ===\r"
    else
      week_output = "=== Week #{week_number} ===\r"
    end
    week_output += "{{start of course week}}\r"
    ordered_blocks = week.blocks.order(:order)
    ordered_blocks.each do |block|
      block_type = block_types[block.kind]
      week_output += "{{#{block_type}#{block.title}}}\r"
      week_output += markdown_to_mediawiki("#{block.content}")
    end
    week_output += "{{end of course week}}\r"
    week_output
  end

  def self.students_table(course)
    students = course.students
    return '' if students.blank?
    table_output = "{{students table}}\r"
    students.each do |student|
      username = student.wiki_id
      assignments = student.assignments.where(course_id: course.id)
      assigned_titles = assignments.assigned.pluck(:article_title)
      assigned = titles_to_wikilinks assigned_titles
      reviewing_titles = assignments.reviewing.pluck(:article_title)
      reviewing = titles_to_wikilinks reviewing_titles
      table_output += "{{student table row|#{username}|#{assigned}|#{reviewing}}}\r"
    end
    table_output += "{{end of students table}}\r"
    table_output
  end
  ################################
  # wikitext formatting methods #
  ################################
  def self.markdown_to_mediawiki(item)
    return PandocRuby.convert(item, from: :markdown, to: :mediawiki)
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

  def self.titles_to_wikilinks(titles)
    return '' if titles.blank?
    wikitext = '[[' + titles.join(']], [[') + ']]'
    wikitext
  end

  #####################
  # Debugging methods #
  #####################
  def self.save_as_file(location, content)
    File.open(location, 'w+') do |f|
      f.write(content)
    end
  end
end
