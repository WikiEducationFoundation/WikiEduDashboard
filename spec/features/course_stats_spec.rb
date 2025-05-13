# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/course_training_progress_manager"

describe 'course stats', type: :feature, js: true do
  include ActionView::Helpers::NumberHelper
  let(:wiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }
  let(:trained) { 1 }
  let(:course) do
    create(:course, trained_count: trained,
                    start: CourseTrainingProgressManager::TRAINING_BOOLEAN_CUTOFF_DATE + 1.day,
                    end: 1.year.from_now.to_date)
  end
  let(:first_revision) { course.start + 1.day }
  # There is no easy way to mock UTC_TIMESTAMP() so this spec depends on the day it runs.
  let(:days_since_first_revision) { (Time.zone.today - first_revision.to_date).floor }
  let(:average_views) { 10 }
  let(:chars)      { 10 }
  let(:student)    { 0 }
  let(:article)    { create(:article, namespace: 0, average_views:) }
  let!(:ac)        do
    create(:articles_course, course_id: course.id, article_id: article.id,
                             new_article: true, first_revision:)
  end
  let(:cwt1) do
    create(:course_wiki_timeslice, course:, wiki:, character_sum: chars, references_count: 5,
           revision_count: 1, start: course.start + 1.day, end: course.start + 2.days)
  end
  let(:cwt2) do
    create(:course_wiki_timeslice, course:, wiki:, character_sum: chars, revision_count: 1,
           start: course.start + 2.days, end: course.start + 3.days)
  end
  let(:user)       { create(:user) }
  let!(:cu)        { create(:courses_user, course_id: course.id, user_id: user.id, role: student) }

  let!(:cwts) { [cwt1, cwt2] }
  let(:articles)   { [article] }
  let(:users)      { [user] }

  it 'displays statistics about the course' do
    course.update_cache_from_timeslices
    visit "/courses/#{course.slug}"
    sleep 1

    expect(page.find('#articles-created')).to have_content articles.count
    expect(page.find('#total-edits')).to have_content cwts.count
    expect(page.find('#articles-edited')).to have_content articles.count
    expect(page.find('#student-editors')).to have_content users.count
    find('#student-editors').click
    expect(page.find('#trained-info')).to have_content trained
    word_count = WordCount.from_characters(chars * cwts.count)
    references_count = cwts.sum(&:references_count)
    expect(page.find('#word-count')).to have_content word_count
    expect(page.find('#references-count')).to have_content references_count
    expect(page.find('#view-count'))
      .to have_content number_to_human(days_since_first_revision * average_views)
  end
end
