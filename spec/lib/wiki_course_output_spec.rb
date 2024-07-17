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
      expect(response).to include('InstructorUser', 'InstructorUser2')
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
