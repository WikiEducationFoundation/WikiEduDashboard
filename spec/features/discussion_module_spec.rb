# frozen_string_literal: true

require 'rails_helper'

describe 'Discussion modules', type: :feature, js: true do
  let(:student) { create(:user) }
  let(:start_date) { 2.weeks.ago.to_date.beginning_of_week }
  let(:course) do
    create(:course, start: start_date, end: start_date + 10.weeks,
                    timeline_start: start_date, timeline_end: start_date + 10.weeks,
                    weekdays: '0101010', submitted: true)
  end
  let(:week) { create(:week, course:, order: 1) }
  let(:discussion) { TrainingModule.find_by(slug: 'thinking-about-wikipedia-discussion') }

  before do
    TrainingModule.load_all
    create(:courses_user, course:, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
    create(:block, week:, kind: Block::KINDS['in_class'], title: 'Discussion',
                   training_module_ids: [discussion.id])
    login_as(student)
  end

  after { logout }

  def view_and_close_prompts
    within '.discussion-module' do
      expect(page).to have_content 'Thinking about Wikipedia'
      expect(page).to have_no_css('a[href*="/training/"]')
      click_button 'View'
    end
    within '.discussion-modal' do
      expect(page).to have_css('h2', text: 'Thinking about Wikipedia')
      expect(page).to have_content 'Does it matter who writes Wikipedia?'
      find('.discussion-modal__actions button').click
    end
    expect(page).to have_no_css('.discussion-modal')
  end

  it 'shows the prompts in a modal on the timeline' do
    visit "/courses/#{course.slug}/timeline"
    view_and_close_prompts
  end

  it 'shows the prompts in a modal on the Resources tab' do
    visit "/courses/#{course.slug}/resources"
    view_and_close_prompts
  end
end
