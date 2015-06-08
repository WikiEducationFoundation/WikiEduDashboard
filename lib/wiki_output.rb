require 'pandoc-ruby'

#= Class for generating wikitext from course information
class WikiOutput
  def self.markdown_to_mediawiki(item)
    return PandocRuby.convert(item, from: :markdown, to: :mediawiki)
  end

  def self.save_as_file(location, content)
    File.open(location, 'w+') do |f|
      f.write(content)
    end
  end

  def self.translate_course(course)
    block_types = ['In Class', 'Assignment', 'Milestone', 'Custom']
    count = 0
    output = ''
    if course.description? && course.description != ''
      output += "#{course.description}"
      output += "\r"
    end
    course.weeks.each do |week|
      week_number = count + 1
      if week.title? && week.title != ''
        output += markdown_to_mediawiki(
          "# Week #{week_number} #{week.title || ''} #")
      end
      week.blocks.each do |block|
        block_type_title = block_types[block.kind] || ''
        block_title = ''
        output += markdown_to_mediawiki("## #{block_type_title} ##")
        if block.title? && block.title != ''
          block_title = "#{block.title}"
          output += markdown_to_mediawiki("### #{block_title} ###")
        end
        output += markdown_to_mediawiki("#{block.content}")
        output += "\r"
      end
      output += '{{end of course week}}'
      output += '\r'
      count += 1
    end

    wiki_output = replace_code_with_nowiki(output)
    wiki_output
  end

  # Replace instances of <code></code> with <nowiki></nowiki>
  # This lets us use backticks to format blocks of mediawiki code that we don't
  # want to be parsed in the on-wiki version of a course page.
  def self.replace_code_with_nowiki(text)
    text.gsub!('<code>', '<nowiki>')
    text.gsub!('</code>', '</nowiki>')
  end
end
