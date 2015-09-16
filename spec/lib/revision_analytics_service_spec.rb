require 'rails_helper'
require "#{Rails.root}/lib/revision_analytics_service"

describe RevisionAnalyticsService do
  let!(:revision)  { create(:revision,
                             id: 1,
                             user_id: 1,
                             article_id: 1,
                             date: 1.day.ago,
                             wp10: 60,
                             ithenticate_id: r1_id) }
  let(:r1_id) { nil }

  describe '#dyk_eligible' do
    let!(:course)    { create(:course, id: 10001, start: 1.month.ago, end: 1.month.from_now) }
    let!(:user)      { create(:user, id: 1, wiki_id: 'Student_1') }
    let!(:c_user)    { create(:courses_user, user_id: 1, course_id: 10001, role: 0) }
    let!(:article)   { create(:article, id: 1, title: 'Student_1/A_great_draft', namespace: 2) }
    let!(:revision5) { create(:revision, id: 5, user_id: 1, article_id: 1, date: 1.week.ago, wp10: 59) }

    let!(:article4)  { create(:article, id: 4, title: 'Student_1/Another_good_draft', namespace: 2) }
    let!(:revision4) { create(:revision, id: 4, user_id: 1, article_id: 4, date: 2.weeks.ago, wp10: 60) }

    # Artciles/Revisions that should not show up
    let!(:article2)  { create(:article, id: 2, title: 'Student_1/A_poor_draft', namespace: 2) }
    let!(:revision2) { create(:revision, id: 2, user_id: 1, article_id: 2, date: 1.day.ago, wp10: 20) }
    let!(:article3)  { create(:article, id: 3, title: 'Student_1/An_old_draft', namespace: 2) }
    let!(:revision3) { create(:revision, id: 3, user_id: 1, article_id: 3, date: 1.year.ago, wp10: 80) }

    subject { described_class.dyk_eligible }

    context 'revisions with sufficient wp10' do
      it 'should be returned' do
        expect(subject[0]).to eq(article)
      end
    end

    context 'revisions with insufficient wp10' do
      it 'should not be returned' do
        expect(subject).not_to include(article2)
      end
    end

    context 'revisions that are too old' do
      it 'should not be returned' do
        expect(subject).not_to include(article3)
      end
    end
  end

  describe '#suspected_plagiarism' do
    subject { described_class.suspected_plagiarism }
    context 'revision with no ithenticate_id' do
      let(:r1_id) { nil }
      it 'should not be included' do
        expect(subject).not_to include(revision)
      end
    end

    context 'revision with ithenticate_id' do
      let(:r1_id) { 5 }
      it 'should be included' do
        expect(subject).to include(revision)
      end
    end
  end
end
