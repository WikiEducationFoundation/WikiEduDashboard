# frozen_string_literal: true

require 'rails_helper'

# Screenshot harness for the peer review exercise: the changed training slides
# and the My Articles peer review checklist. Gated on ENV['SCREENSHOT'] so it
# contributes nothing to the regular suite:
#
#   SCREENSHOT=after bundle exec rspec spec/features/peer_review_screenshots_spec.rb
#
# Output lands in tmp/screenshots/$SCREENSHOT/. Slides that don't exist yet
# (in the baseline pass) are skipped.
describe 'Peer review exercise screenshots', type: :feature, js: true,
         if: ENV['SCREENSHOT'] do
  let(:screenshot_dir) { Rails.root.join('tmp', 'screenshots', ENV.fetch('SCREENSHOT')) }
  let(:student) { create(:user, username: 'Jordan Reyes', onboarded: true) }
  let(:classmate) { create(:user, username: 'Classmate') }
  let(:course) { create(:course) }
  let(:slides) do
    %w[getting-started-with-peer-reviews finding-the-work-to-review posting-your-review
       check-for-reliable-sources checking-the-facts]
  end

  before do
    FileUtils.mkdir_p(screenshot_dir)
    page.current_window.resize_to(1280, 1000)
    TrainingModule.load_all
    stub_info_query
    create(:courses_user, user: student, course:)
    create(:courses_user, user: classmate, course:)
    create(:assignment, course:, article_title: 'Poodle', user: classmate,
                        role: Assignment::Roles::ASSIGNED_ROLE)
    create(:assignment, course:, article_title: 'Poodle', user: student,
                        role: Assignment::Roles::REVIEWING_ROLE)
    login_as(student)
  end

  def shoot(name)
    sleep 0.5
    page.save_screenshot(screenshot_dir.join("#{name}.png"))
  end

  it 'captures the changed training slides' do
    slides.each_with_index do |slug, i|
      next unless TrainingSlide.find_by(slug:)
      visit "/training/students/peer-review/#{slug}"
      expect(page).to have_css('.training__slide')
      shoot(format('slide_%<n>02d_%<slug>s', n: i + 1, slug:))
    end
  end

  it 'captures the peer review checklist' do
    visit "/courses/#{course.slug}"
    click_button 'Peer review checklist'
    expect(page).to have_css('.my-assignment-checklist')
    shoot('checklist')
  end
end
