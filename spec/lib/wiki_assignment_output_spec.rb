require 'rails_helper'
require "#{Rails.root}/lib/wiki_edits"
require "#{Rails.root}/lib/wiki_assignment_output"

describe WikiAssignmentOutput do
  before do
    create(:course,
           id: 10001,
           title: 'Course Title',
           school: 'School',
           term: 'Term',
           slug: 'School/Course_Title_(Term)')
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
    # This UTF-8 username ensures that encoding compatibility issues are handled.
    create(:user, id: 3, username: 'Keï')
    create(:courses_user, user_id: 3, course_id: 10001)
  end

  let(:wiki_assignment_output) do
    WikiAssignmentOutput.new(course, title, talk_title, assignments)
  end
  let(:course) { Course.find(10001) }
  let(:assignments) do
    course.assignments.group_by(&:article_title)[title]
  end

  describe '.build_assignment_page_content' do
    context 'for an existing page' do
      let(:title) { 'Selfie' }
      let(:talk_title) { 'Talk:Selfie' }
      let(:assignments_tag) { wiki_assignment_output.assignments_tag }

      it 'adds an assignment tag to an existing talk page' do
        VCR.use_cassette 'wiki_edits/assignments' do
          selfie_talk = WikiApi.new.get_page_content(talk_title)
          page_content = wiki_assignment_output
                         .build_assignment_page_content(assignments_tag,
                                                        selfie_talk)
          expect(page_content)
            .to include('{{dashboard.wikiedu.org assignment | course = ')
        end
      end

      it 'tags a blank talk page' do
        VCR.use_cassette 'wiki_edits/assignments' do
          page_content = wiki_assignment_output
                         .build_assignment_page_content(assignments_tag,
                                                        '')
          expect(page_content)
            .to include('{{dashboard.wikiedu.org assignment | course = ')
        end
      end

      it 'does not mess things up when the talk page content is not a simple template line' do
        assignment_tag = '{{template|foo=bar}}'
        initial_talk_page_content = "{{ping|Johnjes6}} Greetings! Good start on an article! I had some concrete feedback.\n"

        output = wiki_assignment_output
                 .build_assignment_page_content(assignment_tag,
                                                initial_talk_page_content)
        expected_output = assignment_tag + "\n\n" + initial_talk_page_content
        expect(output).to eq(expected_output)
      end

      it 'puts assignment templates after other top-of-page templates' do
        assignment_tag = '{{template|foo=bar}}'
        talk_page_templates = "{{some template}}\n{{some other template}}\n"
        additional_talk_content = "This is a comment\n"
        initial_talk_page_content = talk_page_templates + additional_talk_content
        output = wiki_assignment_output
                 .build_assignment_page_content(assignment_tag,
                                                initial_talk_page_content)
        expected_output = talk_page_templates + assignment_tag + "\n" + additional_talk_content
        expect(output).to eq(expected_output)
      end

      it 'returns nil if the assignment template is already present' do
        assignment_tag = "{{dashboard.wikiedu.org assignment | course = #{course.wiki_title}"
        talk_page_templates = "{{some template}}\n{{some other template}}\n"
        additional_talk_content = "This is a comment\n"
        initial_talk_page_content = talk_page_templates + assignment_tag + additional_talk_content
        output = wiki_assignment_output
                 .build_assignment_page_content(assignment_tag,
                                                initial_talk_page_content)
        expect(output).to be_nil
      end
    end
  end

  describe '.build_talk_page_update' do
    let(:title) { 'Selfie' }
    let(:talk_title) { 'Talk:Selfie' }

    context 'when the article exists but talk page does not' do
      let(:talk_title) { 'Talk:THIS PAGE DOES NOT EXIST' }

      it 'returns content' do
        VCR.use_cassette 'wiki_edits/talk_page_update' do
          page_content = wiki_assignment_output.build_talk_page_update
          expect(page_content).to include('{{dashboard.wikiedu.org assignment | course = ')
        end
      end
    end

    context 'when neither the talk page nor the article exist' do
      let(:title) { 'THIS PAGE DOES NOT EXIST' }
      let(:talk_title) { 'Talk:THIS PAGE DOES NOT EXIST' }

      it 'returns nil' do
        VCR.use_cassette 'wiki_edits/talk_page_update' do
          page_content = wiki_assignment_output.build_talk_page_update
          expect(page_content).to be_nil
        end
      end
    end

    context 'when the talk page has a disambiguation template' do
      it 'returns nil' do
        allow_any_instance_of(WikiApi).to receive(:get_page_content)
          .and_return('{{WikiProject Disambiguation}}', 'article content')
        page_content = wiki_assignment_output.build_talk_page_update
        expect(page_content).to be_nil
      end
    end

    context 'when the article page has a disambiguation template' do
      it 'returns nil' do
        allow_any_instance_of(WikiApi).to receive(:get_page_content)
          .and_return('talk page content', '{{Disambiguation|airport}}')
        page_content = wiki_assignment_output.build_talk_page_update
        expect(page_content).to be_nil
      end
    end
  end
end
