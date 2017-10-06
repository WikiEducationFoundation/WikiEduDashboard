# frozen_string_literal: true

require 'rails_helper'

describe 'course stats', type: :feature, js: true do
  let(:trained)    { 1 }
  let(:course)     do
    create(:course, trained_count: trained,
                    start: CourseTrainingProgressManager::TRAINING_BOOLEAN_CUTOFF_DATE + 1.day,
                    end: 1.year.from_now.to_date)
  end
  let(:views)      { 10 }
  let(:chars)      { 10 }
  let(:student)    { 0 }
  let(:article)    { create(:article, namespace: 0) }
  let!(:ac)        do
    create(:articles_course, course_id: course.id, article_id: article.id,
                             new_article: true, view_count: views)
  end
  let(:revision) do
    create(:revision, article_id: article.id, characters: chars,
                      date: course.start + 1.day, user_id: user.id)
  end
  let(:revision2) do
    create(:revision, article_id: article.id, new_article: true,
                      characters: chars, date: course.start + 1.day, user_id: user.id)
  end
  let(:user)       { create(:user) }
  let!(:cu)        { create(:courses_user, course_id: course.id, user_id: user.id, role: student) }

  let!(:revisions) { [revision, revision2] }
  let(:articles)   { [article] }
  let(:users)      { [user] }

  it 'displays statistics about the course' do
    cu.update_cache
    course.update_cache
    visit "/courses/#{course.slug}"
    sleep 1

    expect(page.find('#articles-created')).to have_content articles.count
    expect(page.find('#total-edits')).to have_content revisions.count
    expect(page.find('#articles-edited')).to have_content articles.count
    expect(page.find('#student-editors')).to have_content users.count
    find('#student-editors').click
    expect(page.find('#trained-count')).to have_content trained
    word_count = WordCount.from_characters(chars * revisions.count)
    expect(page.find('#word-count')).to have_content word_count
    expect(page.find('#view-count')).to have_content views.to_s
  end
end
