# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wiki_course_output"

describe WikiCourseOutput do
  describe '.translate_course_to_wikitext' do
    let(:student) { create(:user, username: 'StudentUser') }
    let(:instructor) { create(:user, username: 'InstructorUser') }

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
      campaign1 = create(:campaign,
                         id: 1,
                         title: 'Campaign Title 1',
                         slug: 'Campaign Slug 1')
      campaign2 = create(:campaign,
                         id: 2,
                         title: 'Campaign Title 2',
                         slug: 'Campaign Slug 2')
      create(:campaigns_course,
             id: 1,
             campaign: campaign1,
             course: course)
      create(:campaigns_course,
             id: 2,
             campaign: campaign2,
             course: course)
      create(:courses_user,
             user: student,
             course: course,
             role: 0)
      create(:courses_user, user: instructor, course: course, role: 1, real_name: 'Jacque')
      create(:assignment,
             id: 1,
             user: student,
             course: course,
             role: 0,
             article_title: 'My article')
      create(:assignment,
             id: 2,
             user: student,
             course: course,
             role: 1,
             article_title: 'Your article')
      response = described_class.new(course).translate_course_to_wikitext
      expect(response).to include('The course description')
      expect(response).to include('{{start of course timeline')
      expect(response).to include('Block 1 title')
      expect(response).to include('* Overview of the course')
      expect(response).to include('[http://wikiedu.org/editingwikipedia Editing Wikipedia]')
      expect(response).to include('[[My article]]')
      expect(response).to include('[[Your article]]')
      expect(response).to include('{{start of course week|2016-01-11|2016-01-13|2016-01-15}}')
      expect(response).to include('Jacque')
      expect(response).to include('Campaign Title 1, Campaign Title 2')
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
