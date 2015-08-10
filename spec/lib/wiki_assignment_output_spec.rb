require 'rails_helper'
require "#{Rails.root}/lib/wiki_edits"
require "#{Rails.root}/lib/wiki_assignment_output"

describe WikiAssignmentOutput do
  describe '.build_assignment_page_content' do
    it 'should add an assignment tag to the wikitext of a page' do
      VCR.use_cassette 'wiki_edits/assignments' do
        create(:assignment,
               id: 1,
               user_id: 3,
               course_id: 10001,
               article_title: 'Selfie',
               role: 0)
        create(:assignment,
               id: 2,
               user_id: 3,
               course_id: 10001,
               article_title: 'Selfie',
               role: 1)
        create(:user,
               id: 3,
               wiki_id: 'Ragesock')
        create(:courses_user,
               user_id: 3,
               course_id: 10001)
        course = create(:course,
                        id: 10001,
                        title: 'Course Title',
                        school: 'School',
                        term: 'Term',
                        slug: 'School/Course_Title_(Term)')
        talk_title = 'Talk:Selfie'
        selfie_talk = Wiki.get_page_content(talk_title)

        course_page = course.wiki_title
        assignment_titles = WikiEdits.assignments_by_article(course, nil, nil)
        title_assignments = assignment_titles['Selfie']
        assignment_tag = WikiAssignmentOutput.assignments_tag(course_page,
                                                              title_assignments)
        page_content = WikiAssignmentOutput
                       .build_assignment_page_content(assignment_tag,
                                                      course_page,
                                                      selfie_talk)
        pp page_content
        expect(page_content)
          .to include('{{dashboard.wikiedu.org assignment | course = ')
        page_content = WikiAssignmentOutput
                       .build_assignment_page_content(assignment_tag,
                                                      course_page,
                                                      '')
        expect(page_content)
          .to include('{{dashboard.wikiedu.org assignment | course = ')
      end
    end
  end
end
