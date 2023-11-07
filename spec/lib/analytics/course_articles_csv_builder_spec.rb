# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/analytics/course_articles_csv_builder')

describe CourseArticlesCsvBuilder do
  let(:course) { create(:course) }
  let(:user) { create(:user, registered_at: course.start + 1.minute) }
  let!(:courses_user) { create(:courses_user, course:, user:) }

  let(:article) { create(:article, title: 'First_Article') }
  let(:article2) { create(:article, title: 'Second_Article') }
  let(:revision_count) { 5 }
  let(:subject) { described_class.new(course).generate_csv }

  before do
    # multiple revisions for first article
    revision_count.times do |i|
      create(:revision, mw_rev_id: i, user:, date: course.start + 1.minute, article:)
    end
    # one revision for second article
    create(:revision, mw_rev_id: 123, user:, date: course.start + 1.minute, article: article2)
    # revisions with nil and characters, to make sure this does not cause problems
    create(:revision, mw_rev_id: 124, user:, date: course.start + 1.minute, article: article2,
                      characters: nil)
    create(:revision, mw_rev_id: 125, user:, date: course.start + 1.minute, article: article2,
                      characters: -500)
  end

  it 'creates a CSV with a header and a row of data for each article' do
    expect(subject.split("\n").count).to eq(3)
  end

  it 'creates an edited CSV article with a rating column' do
    article_headers = subject.split('\n').first
    expect(article_headers.include?('rating')).to be true
  end

  it 'excludes untracked articles' do
    create(:articles_course, course:, article:, tracked: false)
    create(:articles_course, course:, article: article2, tracked: true)
    expect(subject.split("\n").count).to eq(2)
    expect(subject).not_to include(article.title)
    expect(subject).to include(article2.title)
  end

  context 'for an ArticleScopedProgram' do
    let(:course) { create(:article_scoped_program) }

    before do
      create(:assignment, user:, course:, article:)
    end

    it 'only includes in-scope articles' do
      expect(subject.split("\n").count).to eq(2)
      expect(subject).to include(article.title)
      expect(subject).not_to include(article2.title)
    end
  end

  it 'handles missing Article records gracefully' do
    article.destroy
    expect(subject).not_to include('First_Article')
    expect(subject).to include('Second_Article')
  end
end
