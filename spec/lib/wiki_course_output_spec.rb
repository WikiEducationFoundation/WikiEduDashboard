require 'rails_helper'
require "#{Rails.root}/lib/wiki_course_output"

describe WikiCourseOutput do
  describe '.markdown_to_mediawiki' do
    it 'should return a wikitext formatted version of the markdown input' do
      title = WikiCourseOutput.markdown_to_mediawiki('# Title #')
      text = WikiCourseOutput.markdown_to_mediawiki('This is some plain text')
      response = title + text
      expect(response).to eq("= Title =\n\nThis is some plain text\n\n")
    end
  end

  describe '.replace_code_with_nowiki' do
    it 'should convert code formatting syntax from html to wikitext' do
      code_snippet = '<code></code>'
      response = WikiCourseOutput.replace_code_with_nowiki(code_snippet)
      expect(response).to eq('<nowiki></nowiki>')
    end

    it 'should not return nil if there are no code snippet' do
      code_snippet = 'no code snippet here'
      response = WikiCourseOutput.replace_code_with_nowiki(code_snippet)
      expect(response).to eq('no code snippet here')
    end
  end

  describe '.replace_at_sign_with_template' do
    it 'should reformat email addresses' do
      code_snippet = 'My email is email@example.com.'
      response = WikiCourseOutput.replace_at_sign_with_template(code_snippet)
      expect(response).to eq('My email is email{{@}}example.com.')
    end
  end

  describe '.substitute_bad_links' do
    it 'should find links and munge them into readable non-urls' do
      code_snippet = 'My bad links are bit.ly/foo and http://ur1.ca/bar'
      bad_links = ['bit.ly/foo', 'ur1.ca/bar']
      response = WikiCourseOutput.substitute_bad_links(code_snippet, bad_links)
      expect(response).to include 'bit(.)ly/foo'
      expect(response).to include 'ur1(.)ca/bar'
      expect(response).not_to include 'bit.ly/foo'
      expect(response).not_to include 'ur1.ca/bar'
    end
  end

  describe '.translate_course' do
    it 'should return a wikitext version of the course' do
      week1 = create(:week, id: 2)
      week2 = create(:week, id: 3)
      block1 = create(:block,
                      id: 4,
                      title: 'Block 1 title',
                      kind: 0,
                      content: 'block 1 content')
      markdown_with_image = 'block 2 content with ![image](https://upload.wikimedia.org/wikipedia/commons/6/6b/View_from_Imperia_Tower_Moscow_04-2014_img12.jpg)'
      block2 = create(:block,
                      id: 5,
                      title: nil,
                      kind: 1,
                      content: markdown_with_image)
      week1.blocks = [block1]
      week2.blocks = [block2]
      create(:user,
             id: 1,
             wiki_id: 'Ragesock')
      course = create(:course,
                      id: 1,
                      title: '# Title #',
                      description: 'The course description',
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
      response = WikiCourseOutput.translate_course(course)
      expect(response).to include('The course description')
      expect(response).to include('Block 1 title')
      expect(response).to include('block 2 content')
      expect(response).to match(/[Image|File]:View_from_Imperia_Tower_Moscow_04-2014_img12\.jpg/)
      expect(response).to include('[[My article]]')
      expect(response).to include('[[Your article]]')
    end
  end
end
