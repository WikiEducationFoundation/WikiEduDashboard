require 'rails_helper'
require "#{Rails.root}/lib/wiki_course_output"

describe WikiCourseOutput do
  describe '.translate_course_to_wikitext' do
    it 'returns a wikitext version of the course' do
      week1 = create(:week, id: 2)
      week2 = create(:week, id: 3)
      block1 = create(:block,
                      id: 4,
                      title: 'Block 1 title',
                      kind: 0,
                      content: 'block 1 content')
      html_with_link = '<ul>\n  <li>Overview of the course</li>\n  <li>Introduction'\
        ' to how Wikipedia will be used in the course</li>\n  <li>Understanding'\
        ' Wikipedia as a community, we\'ll discuss its expectations and etiquette.'\
        '</li>\n</ul>\n<hr />\n<p>Handout: <a href="http://wikiedu.org/editingwikipedia">'\
        'Editing Wikipedia</a></p>\n'
      block2 = create(:block,
                      id: 5,
                      title: nil,
                      kind: 1,
                      content: html_with_link)
      week1.blocks = [block1]
      week2.blocks = [block2]
      create(:user,
             id: 1,
             username: 'Ragesock')
      markdown_with_image = 'The course description with ![image]'\
      '(https://upload.wikimedia.org/wikipedia/commons/6/6b/View_from_Imperia_Tower'\
      '_Moscow_04-2014_img12.jpg)'
      course = create(:course,
                      id: 1,
                      title: '# Title #',
                      description: markdown_with_image,
                      weekdays: '0101010',
                      start: '2016-01-11',
                      end: '2016-04-24',
                      timeline_start: '2016-01-11',
                      timeline_end: '2016-04-24',
                      weeks: [week1, week2])
      create(:courses_user,
             user_id: 1,
             course_id: 1,
             role: 0)
      create(:assignment,
             id: 1,
             user_id: 1,
             course_id: 1,
             role: 0,
             article_title: 'My article')
      create(:assignment,
             id: 2,
             user_id: 1,
             course_id: 1,
             role: 1,
             article_title: 'Your article')
      response = WikiCourseOutput.new(Course.find(1)).translate_course_to_wikitext
      expect(response).to include('The course description')
      expect(response).to include('Block 1 title')
      expect(response).to include('* Overview of the course')
      expect(response).to include('[http://wikiedu.org/editingwikipedia Editing Wikipedia]')
      expect(response).to include('[[My article]]')
      expect(response).to include('[[Your article]]')
      expect(response).to include('{{start of course week|2016-01-11|2016-01-13|2016-01-15}}')
    end
  end
end
