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
    let!(:article2)  { create(:article, id: 2, title: 'Student_1/A_poor_draft', namespace: 2) }
    let!(:revision2) { create(:revision, id: 2, user_id: 1, article_id: 2, date: 1.day.ago, wp10: 20) }

    subject { described_class.dyk_eligible }

    context 'sufficient wp10' do
      it 'should return relevant revisions' do
        expect(subject).to include(article)
      end
    end

    context 'insufficient wp10' do
      it 'should not return irrelevant revisions' do
        expect(subject).not_to include(article2)
      end
    end
  end


  describe '#suspected_plagiarism' do
    subject { described_class.suspected_plagiarism }
    context 'no ithenticate_id' do
      let(:r1_id) { nil }
      it 'does not include revision' do
        expect(subject).not_to include(revision)
      end
    end

    context 'ithenticate_id present' do
      let(:r1_id) { 5 }
      it 'does include revision' do
        expect(subject).to include(revision)
      end
    end
  end
end
