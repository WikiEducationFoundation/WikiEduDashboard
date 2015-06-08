require 'pandoc-ruby'


class WikiOutput
  def self.markdown_to_mediawiki(item)
    return PandocRuby.convert(item, :from => :markdown, :to => :mediawiki)
  end

  def self.html_to_mediawiki(item)
    return PandocRuby.convert(item, :from => :html, :to => :mediawiki)
  end

  def self.save_as_file(location, content)
    File.open(location,"w+") do |f|
      f.write(content)
    end
  end

  def self.translate_course(course, current_user)
    block_types = ['In Class', 'Assignment', 'Milestone', 'Custom']
    count = 0
    output = ""
    if course.description? && course.description != ""
      output += "#{course.description}"
      output += html_to_mediawiki "<br/><br/>"
    end
    course.weeks.each do |week|
      week_number = count + 1
      output += "{{start of course week}}"
      output += html_to_mediawiki "<br/>"
      if week.title? && week.title != ''
        output += html_to_mediawiki("<h2> Week #{week_number}: #{week.title} </h2>")
      else
        output += html_to_mediawiki("<h2> Week #{week_number} </h2>")
      end
      sorted_blocks = week.blocks.order(:order)
      sorted_blocks.each do |block|
        block_type_title = block_types[block.kind] || ''
        block_title = ''
        output += html_to_mediawiki("<h3> #{block_type_title} </h3>")
        if block.title? && block.title != ''
          block_title = "#{block.title}"
          output += html_to_mediawiki("<h4> #{block_title} </h4>")
        end
        output += markdown_to_mediawiki("#{block.content}")
        output += html_to_mediawiki "<br/>"
      end
      output += "{{end of course week}}"
      output += html_to_mediawiki "<br/>"
      count+=1
    end
    wiki_output = "{{course details 
     | course_name = #{course.title} 
     | instructor_username = #{current_user.wiki_id} 
     | instructor_realname = #{current_user.wiki_id}  
     | subject = #{course.subject} 
     | start_date = #{course.start} 
     | end_date = #{course.end} 
     | institution =  #{course.school} 
     | expected_students = #{course.user_count} 
     | assignment_page = User:#{current_user.wiki_id}/#{course.slug}
     | wiki_ed = yes
     | interested_in_DYK = no
     | interested_in_Good_Articles = no
    }}"
    wiki_output += html_to_mediawiki "<br/>"

    wiki_output += output
    return wiki_output
  end

end