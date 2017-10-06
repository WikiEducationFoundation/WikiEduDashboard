# frozen_string_literal: true

require 'rails_helper'

describe RevisionStat do
  let(:created_date)     { 1.day.ago }
  let!(:user)            { create(:user) }
  let!(:article)         { create(:article) }
  let!(:revision) do
    create(:revision, article_id: article.id, date: created_date, user_id: user.id)
  end
  let!(:course)          { create(:course) }
  let!(:articles_course) do
    create(:articles_course, article_id: article.id, course_id: course.id)
  end

  let(:date) { 7.days.ago.to_date }

  describe '#get_records' do
    subject { RevisionStat.get_records(date: date, course_id: course.id) }

    context 'date' do
      context 'older than 7 days' do
        let(:created_date) { 1.year.ago.to_date }
        it 'does not include in scope' do
          expect(subject).to eq(0)
        end
      end

      context 'in timeframe' do
        it 'does include in scope' do
          expect(subject).to eq(1)
        end
      end
    end

    context 'course id' do
      context 'not for this course' do
        before { course.update_column(:id, 1000) }
        it 'does not include in scope' do
          expect(subject).to eq(0)
        end
      end

      context 'for this course' do
        it 'does include in scope' do
          expect(subject).to eq(1)
        end
      end
    end
  end

  describe '#recent_revisions_for_user_and_course' do
    let(:courses_user) { create(:courses_user, course_id: course.id, user_id: user.id) }
    subject { RevisionStat.recent_revisions_for_courses_user(courses_user) }
    context 'date' do
      context 'older than 7 days' do
        let(:created_date) { 8.days.ago }
        it 'does not include' do
          expect(subject).not_to include(revision)
        end
      end
      context '2 days' do
        let(:created_date) { 2.days.ago }
        it 'does not include' do
          expect(subject).to include(revision)
        end
      end
    end

    context 'for user' do
      before { user.update_attribute(:id, user_id) }
      context 'user has courses users' do
        let(:user_id) { user.id }
        it 'does not include' do
          expect(subject).to include(revision)
        end
      end
      context 'user has no courses users' do
        let(:user_id) { 'potatoes' }
        it 'does not include' do
          expect(subject).not_to include(revision)
        end
      end
    end

    context 'revisions' do
      context 'user has revisions' do
        it 'is not empty' do
          expect(subject.count).to be > 0
        end
      end
      context 'user has no revisions' do
        before { revision.update_attribute(:user_id, (user.id - 1)) }
        it 'is empty' do
          expect(subject.count).to eq(0)
        end
      end
    end
  end
end
