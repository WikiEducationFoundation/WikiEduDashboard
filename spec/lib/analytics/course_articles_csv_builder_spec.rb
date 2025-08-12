# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/course_articles_csv_builder"

describe CourseArticlesCsvBuilder do
  let(:course) { create(:course) }
  let(:user) { create(:user, registered_at: course.start + 1.minute) }
  let(:another_user) { create(:user, username: 'Absa', registered_at: course.start + 1.minute) }

  let(:article) { create(:article, title: 'First_Article') }
  let(:article2) { create(:article, title: 'Second_Article') }
  let(:revision_count) { 5 }
  let(:subject) { described_class.new(course).generate_csv }

  before do
    # add courses users
    create(:courses_user, course:, user:)
    create(:courses_user, course:, user: another_user)

    # multiple timeslices for first article
    revision_count.times do |i|
      create(:article_course_timeslice, course:, article:, user_ids: [user.id, another_user.id],
               start: course.start + i.days, end: course.start + (i + 1).days, revision_count: i,
               character_sum: 2 * i)
    end
    create(:article_course_timeslice, course:, article: article2, user_ids: [user.id],
           start: course.start + 1.day, end: course.start + 2.days, revision_count: 4,
           character_sum: 1000)
    create(:article_course_timeslice, course:, article: article2, user_ids: [another_user.id],
           start: course.start + 3.days, end: course.start + 4.days, revision_count: 4,
           character_sum: 500)
  end

  it 'creates a CSV with a header and a row of data for each article' do
    expect(subject.split("\n").count).to eq(3)
  end

  it 'creates an edited CSV article with a rating column' do
    article_headers = subject.split("\n").first
    expect(article_headers.include?('rating')).to be true
  end

  it 'metrics are right' do
    first_row = subject.split("\n").second.split(',')
    expect(first_row[4]).to include('Ragesock') # usernames
    expect(first_row[5]).to include('Absa') # usernames
    expect(first_row[7]).to eq('10') # edit_count
    expect(first_row[8]).to eq('20') # characters_added
  end

  it 'excludes untracked articles' do
    ArticleCourseTimeslice.where(course:, article:).update(tracked: false)
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
