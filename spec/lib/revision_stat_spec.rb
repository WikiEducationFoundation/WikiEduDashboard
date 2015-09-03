require 'rails_helper'

describe RevisionStat do
  let(:created_date)     { 1.day.ago }
  let!(:article)         { create(:article) }
  let!(:revision) do
    create(:revision, article_id: article.id, date: created_date)
  end
  let!(:course)          { create(:course) }
  let!(:articles_course) do
    create(:articles_course, article_id: article.id, course_id: course.id)
  end

  let(:date) { 7.days.ago.to_date }

  describe '#get_records' do
    subject { RevisionStat.get_records(date, course.id) }

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
end
