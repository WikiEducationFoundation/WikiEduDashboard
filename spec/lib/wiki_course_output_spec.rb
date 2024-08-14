# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wiki_course_output"

describe WikiCourseOutput do
  describe '.translate_course_to_wikitext' do
    markdown_with_image = 'The course description with ![image]'\
                          '(https://upload.wikimedia.org/wikipedia/commons/6/6b/View_from_Imperia_Tower'\
                          '_Moscow_04-2014_img12.jpg)'

    let(:student) { create(:user, username: 'StudentUser') }
    let(:instructor) { create(:user, username: 'InstructorUser') }
    let(:instructor2) { create(:user, username: 'InstructorUser2') }
    let(:instructor3) { create(:user, username: 'InstructorUser3') }
    let(:course) do
      create(:course,
             title: '# Title #',
             description: markdown_with_image,
             weekdays: '0101010',
             start: '2016-01-11',
             end: '2016-04-24',
             timeline_start: '2016-01-11',
             timeline_end: '2016-04-24')
    end

    it 'returns a wikitext version of the course' do
      week1 = create(:week, id: 2, course:)
      week2 = create(:week, id: 3, course:)
      create(:block,
             id: 4,
             title: 'Block 1 title',
             kind: 0,
             content: 'block 1 content',
             week: week1)
      html_with_link = '<ul>\n  <li>Overview of the course</li>\n  <li>Introduction'\
                       ' to how Wikipedia will be used in the course</li>\n  <li>Understanding'\
                       ' Wikipedia as a community, we\'ll discuss its expectations and etiquette.'\
                       '</li>\n</ul>\n<hr />\n<p>Handout: <a href="http://wikiedu.org/editingwikipedia">'\
                       'Editing Wikipedia</a></p>\n'
      create(:block,
             id: 5,
             title: nil,
             kind: 1,
             content: html_with_link,
             week: week2)
      create(:user,
             id: 1,
             username: 'Ragesock')

      campaign1 = create(:campaign,
                         title: 'Campaign Title 1',
                         slug: 'Campaign Slug 1')
      campaign2 = create(:campaign,
                         title: 'Campaign Title 2',
                         slug: 'Campaign Slug 2')
      create(:campaigns_course,
             campaign: campaign1,
             course:)
      create(:campaigns_course,
             campaign: campaign2,
             course:)
      create(:courses_user,
             user: student,
             course:,
             role: 0)
      create(:courses_user, user: instructor, course:, role: 1, real_name: 'Jacque')
      create(:courses_user, user: instructor2, course:, role: 1, real_name: 'Marie')
      create(:courses_user, user: instructor3, course:, role: 1, real_name: 'Sarah')
      create(:assignment,
             id: 1,
             user: student,
             course:,
             role: 0,
             article_title: 'My article')
      create(:assignment,
             id: 2,
             user: student,
             course:,
             role: 1,
             article_title: 'Your article')
      response = described_class.new(course.reload).translate_course_to_wikitext
      expect(response).to include('The course description')
      expect(response).to include('[[My article]]')
      expect(response).to include('[[Your article]]')
      expect(response).to include('Jacque')
      expect(response).to include('Campaign Title 1, Campaign Title 2')
      expect(response).to include('InstructorUser', 'InstructorUser2', 'InstructorUser3')
    end

    it 'generates correct wikitext for a course with multiple instructors' do
      course = create(:course,
                      title: 'Advanced Legal Research Winter 2020',
                      description: 'Course description',
                      school: 'Stanford Law School',
                      term: 'Winter',
                      slug: 'Stanford_Law_School/Advanced_Legal_Research_Winter_2020_(Winter)',
                      subject: 'Legal Research',
                      start: '2024-02-01',
                      end: '2024-09-13',
                      expected_students: 25)

      instructor1 = create(:user, username: 'Tlmarks')
      instructor2 = create(:user, username: 'Shelbaum')
      instructor3 = create(:user, username: 'Abishekdascs')

      create(:courses_user, user: instructor1, course:,
      role: CoursesUsers::Roles::INSTRUCTOR_ROLE, real_name: 'Terry Marks')
      create(:courses_user, user: instructor2, course:,
      role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      create(:courses_user, user: instructor3, course:,
      role: CoursesUsers::Roles::INSTRUCTOR_ROLE)

      create(:campaign, id: 1, title: 'Default Campaign')
      create(:campaigns_course, course:, campaign_id: 1)

      allow(ENV).to receive(:[]).with('dashboard_url').and_return('outreachdashboard.wmflabs.org')

      output = described_class.new(course.reload).translate_course_to_wikitext

      expected_output = <<~WIKITEXT
        {{program details
         | course_name = Advanced Legal Research Winter 2020
         | instructor_username = Tlmarks
         | instructor_realname = Terry Marks
         | instructor_username_2 = Shelbaum
         | instructor_username_3 = Abishekdascs
         | support_staff =#{' '}
         | subject = Legal Research
         | start_date = 2024-02-01 00:00:00 UTC
         | end_date = 2024-09-13 23:59:59 UTC
         | institution = Stanford Law School
         | expected_students = 25
         | assignment_page =#{' '}
         | slug = Stanford_Law_School/Advanced_Legal_Research_Winter_2020_(Winter)
         | campaigns = Default Campaign
         | outreachdashboard.wmflabs.org = yes
        }}
      WIKITEXT

      expect(output).to include(expected_output.strip)
      expect(output).to include('Course description')
    end

    context 'when the course has no weeks or users or anything' do
      let(:course) { create(:course) }
      let(:subject) { described_class.new(course).translate_course_to_wikitext }

      it 'excludes the timeline for a course with no weeks' do
        expect(subject).not_to include('{{start of course timeline')
      end
    end
  end
end
