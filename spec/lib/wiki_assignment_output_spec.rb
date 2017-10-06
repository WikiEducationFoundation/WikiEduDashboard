# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wiki_edits"
require "#{Rails.root}/lib/wiki_assignment_output"

describe WikiAssignmentOutput do
  before do
    create(:course,
           id: 10001,
           title: 'Language in Hawaiʻi and the Pacific',
           school: 'University of Hawaiʻi at Mānoa',
           term: 'Fall 2016',
           slug: 'University_of_Hawaiʻi_at_Mānoa/Language_in_Hawaiʻi_and_the_Pacific_(Fall_2016)')
    create(:assignment,
           id: 1,
           user_id: 3,
           course_id: 10001,
           article_title: 'South_Efate_language',
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
  let(:templates) do
    template_file_path = "config/templates/#{ENV['dashboard_url']}_#{course.home_wiki.language}.yml"
    YAML.load_file(Rails.root + template_file_path)
  end

  let(:wiki_assignment_output) do
    WikiAssignmentOutput.new(course, title, talk_title, assignments, templates)
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

      it 'puts assignment templates after a nested template like {{WikiProject banner shell}} ends' do
        assignment_tag = '{{template|foo=bar}}'
        initial_talk_page_content = <<~KANYEWESTTALK
          {{Talk header}}
          {{Controversial}}
          {{User:MiszaBot/config
            | algo=old(90d)
            | archive=Talk:Kanye West/Archive %(counter)d
            | counter=1
            | maxarchivesize=75K
            | archiveheader={{Automatic archive navigator}}
            | minthreadsleft=5
            | minthreadstoarchive=2
          }}
          {{Article history
          |action1=GAN
          |action1date=20:38, 27 April 2008 (UTC)
          |action1link=Talk:Kanye West/Archive 2#GA review
          |action1result=passed
          |action1oldid=208600243
          |currentstatus=GA
          |topic=music
          }}
          {{WikiProject banner shell|collapsed=yes|blp=yes|1=
          {{WikiProject Biography|living=yes|class=GA|musician-priority=Mid|listas=West, Kanye|musician-work-group=yes}}
          {{WikiProject Hip hop|class=GA|importance=high}}
          {{WikiProject Chicago|class=GA|importance=mid}}
          {{WikiProject Illinois|class=GA|importance=Mid}}
          {{WikiProject Record Production|class=GA|importance=High}}
          }}
          {{findnotice}}
          {{high traffic|date=17 February 2016|url=/news/article-3450364/Loser-com-redirects-Kanye-s-Wikipedia-page-recent-string-Twitter-rants.html|notlinked=yes|site=Mail Online}}
        KANYEWESTTALK
        output = wiki_assignment_output
                 .build_assignment_page_content(assignment_tag,
                                                initial_talk_page_content)
        expected_output = initial_talk_page_content + assignment_tag + "\n"
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

      context 'when the assignment is being removed so the new tag is blank' do
        let(:title) { 'South_Efate_language' }
        let(:talk_title) { 'Talk:South_Efate_language' }
        it 'removes the existing assignment template if the new tag is blank' do
          old_content = '{{dashboard.wikiedu.org assignment | course = Wikipedia:Wiki_Ed/University_of_Hawaiʻi_at_Mānoa/Language_in_Hawaiʻi_and_the_Pacific_(Fall_2016) | assignments = [[User:Keï|Keï]] }}

  {{WP Languages|class=Stub}}
  {{WikiProject Melanesia|class=Stub|Vanuatu=yes}}
  '
          page_content = wiki_assignment_output
                         .build_assignment_page_content(
                           '', String.new(old_content).force_encoding('ASCII-8BIT')
                         )
          expect(page_content).not_to include('{{dashboard.wikiedu.org assignment')
        end
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
          .and_return('{{WikiProject Disambiguation}}')
        page_content = wiki_assignment_output.build_talk_page_update
        expect(page_content).to be_nil
      end
    end

    context 'when the article page has a disambiguation template' do
      it 'returns nil' do
        talk_page_response = double('wiki')
        article_page_response = double('wiki')
        allow(WikiApi).to receive(:new)
          .and_return(talk_page_response, article_page_response)
        allow(talk_page_response).to receive(:get_page_content)
          .and_return('talk page content')
        allow(article_page_response).to receive(:get_page_content)
          .and_return('{{Disambiguation|airport}}')
        page_content = wiki_assignment_output.build_talk_page_update
        expect(page_content).to be_nil
      end
    end
  end
end
