# frozen_string_literal: true

# Manual-only: captures before/after screenshots of pages we're auditing
# for accessibility. Run with:
#   SCREENSHOT_SUFFIX=before bundle exec rspec spec/features/a11y_screenshots.rb --tag screenshots
#   # ...make changes, yarn build...
#   SCREENSHOT_SUFFIX=after bundle exec rspec spec/features/a11y_screenshots.rb --tag screenshots
#
# Each example sets up minimal fixtures for its target page and saves a
# screenshot to tmp/screenshots/<page>_<suffix>.png.

require 'rails_helper'

describe 'accessibility screenshots', type: :feature, js: true, screenshots: true do
  let(:screenshot_dir) { Rails.root.join('tmp', 'screenshots') }
  let(:suffix) { ENV['SCREENSHOT_SUFFIX'] || 'now' }

  before do
    FileUtils.mkdir_p(screenshot_dir)
    page.current_window.resize_to(1440, 1000)
  end

  describe 'course timeline' do
    let(:start_date) { '2025-02-10'.to_date }
    let(:course) do
      create(:course, start: start_date, end: start_date + 2.months,
                      timeline_start: start_date, timeline_end: start_date + 2.months,
                      weekdays: '0101010', submitted: true)
    end
    let!(:week) { create(:week, course:) }
    let!(:block1) do
      create(:block, week:, id: 1, kind: Block::KINDS['assignment'],
                     title: 'Block Title', training_module_ids: [1], order: 0, points: 50)
    end
    let!(:block2) do
      create(:block, week:, id: 2, kind: Block::KINDS['in_class'],
                     title: 'Another Title', training_module_ids: [2], order: 1)
    end
    let!(:block3) do
      create(:block, week:, id: 3, kind: Block::KINDS['milestone'],
                     title: 'Third Title', training_module_ids: [3], points: 7, order: 2)
    end

    before { TrainingModule.load_all; login_as(create(:admin)); stub_oauth_edit }

    it 'snapshot' do
      visit "/courses/#{course.slug}/timeline"
      expect(page).to have_content 'Block Title'
      sleep 1
      page.save_screenshot(screenshot_dir.join("course_timeline_#{suffix}.png"))
    end
  end
end
