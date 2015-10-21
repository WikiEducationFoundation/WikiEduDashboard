require 'rails_helper'
require "#{Rails.root}/lib/wiki_edits"
require "#{Rails.root}/lib/wiki_assignment_output"

describe WikiAssignmentOutput do
  before do
    create(:assignment,
           id: 1,
           user_id: 3,
           course_id: 10001,
           article_title: 'Selfie',
           role: Assignment::Roles::ASSIGNED_ROLE)
    create(:assignment,
           id: 2,
           user_id: 3,
           course_id: 10001,
           article_title: 'Selfie',
           role: Assignment::Roles::REVIEWING_ROLE)
    create(:user,
           id: 3,
           wiki_id: 'Ragesock')
    create(:courses_user,
           user_id: 3,
           course_id: 10001)
    create(:course,
           id: 10001,
           title: 'Course Title',
           school: 'School',
           term: 'Term',
           slug: 'School/Course_Title_(Term)')
  end

  describe '.build_assignment_page_content' do
    it 'should add an assignment tag to the wikitext of a page' do
      VCR.use_cassette 'wiki_edits/assignments' do
        talk_title = 'Talk:Selfie'
        selfie_talk = Wiki.get_page_content(talk_title)
        course = Course.find(10001)
        course_page = course.wiki_title
        assignment_titles = WikiEdits.assignments_grouped_by_article_title(course)
        title_assignments = assignment_titles['Selfie']
        assignment_tag = WikiAssignmentOutput.assignments_tag(course_page,
                                                              title_assignments)
        page_content = WikiAssignmentOutput
                       .build_assignment_page_content(assignment_tag,
                                                      course_page,
                                                      selfie_talk)
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

  describe '.build_talk_page_update' do
    it 'should return content even if the talk page does not yet exist' do
      VCR.use_cassette 'wiki_edits/talk_page_update' do
        existing_title = 'Selfie'
        missing_talk_title = 'Talk:THIS PAGE DOES NOT EXIST'
        course = Course.find(10001)
        course_page = course.wiki_title
        assignment_titles = WikiEdits.assignments_grouped_by_article_title(course)
        title_assignments = assignment_titles['Selfie']

        # Try the case of where the article exists
        page_content = WikiAssignmentOutput
                       .build_talk_page_update(existing_title,
                                               missing_talk_title,
                                               title_assignments,
                                               course_page)
        expect(page_content)
          .to include('{{dashboard.wikiedu.org assignment | course = ')

        # Try the case where the article does not exist.
        missing_title = 'THIS PAGE DOES NOT EXIST'
        page_content = WikiAssignmentOutput
                       .build_talk_page_update(missing_title,
                                               missing_talk_title,
                                               title_assignments,
                                               course_page)
        expect(page_content).to be_nil
      end
    end
  end
end
