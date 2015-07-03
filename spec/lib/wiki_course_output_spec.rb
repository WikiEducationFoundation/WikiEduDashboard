require 'rails_helper'
require "#{Rails.root}/lib/wiki_course_output"

describe WikiCourseOutput do
  describe '.markdown_to_mediawiki' do
    it 'should return a wikitext formatted version of the markdown input' do
      title = WikiCourseOutput.markdown_to_mediawiki('# Title #')
      text = WikiCourseOutput.markdown_to_mediawiki('This is some plain text')
      response =  title + text
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

  describe '.translate_course' do
    it 'should return a wikitext version of the course' do
      week1 = create(:week, id: 2, title: 'This is the beginning')
      week2 = create(:week, id: 3)
      block1 = create(:block,
                      id: 4,
                      title: 'Block 1 title',
                      kind: 0,
                      content: 'block 1 content')
      block2 = create(:block,
                      id: 5,
                      title: nil,
                      kind: 1,
                      content: 'block 2 content')
      week1.blocks = [block1]
      week2.blocks = [block2]
      user = create(:user,
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
      expect(response).to include('This is the beginning')
      expect(response).to include('Block 1 title')
      expect(response).to include('block 2 content')
      expect(response).to include('[[My article]]')
      expect(response).to include('[[Your article]]')
    end
  end
end
