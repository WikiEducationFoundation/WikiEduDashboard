require 'pandoc-ruby'

#= Class for generating wikitext from course information
class WikiOutput
  def self.markdown_to_mediawiki(item)
    return PandocRuby.convert(item, from: :markdown, to: :mediawiki)
  end

  def self.html_to_mediawiki(item)
    return PandocRuby.convert(item, from: :html, to: :mediawiki)
  end

  def self.save_as_file(location, content)
    File.open(location, 'w+') do |f|
      f.write(content)
    end
  end

  def self.translate_course(course, current_user)
    block_types = ['in class',
                   'assignment',
                   'assignment milestones',
                   'assignment'] # TODO: get the custom value
    count = 0

    # Course description and details
    output = course_details_and_description(course, current_user)

    # Timeline
    output += "{{start of course timeline}}\r"
    course.weeks.each do |week|
      count += 1
      week_number = count
      output += "=== Week #{week_number}: #{week.title || ''} ===\r"
      output += "{{start of course week}}\r"
      week.blocks.each do |block|
        block_type = block_types[block.kind] || ''
        output += "{{#{block_type}|#{block.title}}}\r"
        output += markdown_to_mediawiki("#{block.content}")
        output += "\r"
      end
      output += "{{end of course week}}\r"
    end

    wiki_output = replace_code_with_nowiki(output)
    wiki_output
  end

  def self.course_details_and_description(course, instructor)
    course_details = "{{course details
     | course_name = #{course.title}
     | instructor_username = #{instructor.wiki_id}
     | instructor_realname = #{instructor.wiki_id}
     | subject = #{course.subject}
     | start_date = #{course.start}
     | end_date = #{course.end}
     | institution =  #{course.school}
     | expected_students = #{course.user_count}
     | assignment_page = User:#{instructor.wiki_id}/#{course.slug}
    }}"
    description = markdown_to_mediawiki("#{course.description}")
    course_details + "\r" + description
  end

  # Replace instances of <code></code> with <nowiki></nowiki>
  # This lets us use backticks to format blocks of mediawiki code that we don't
  # want to be parsed in the on-wiki version of a course page.
  def self.replace_code_with_nowiki(text)
    text.gsub!('<code>', '<nowiki>')
    text.gsub!('</code>', '</nowiki>')
  end
end
