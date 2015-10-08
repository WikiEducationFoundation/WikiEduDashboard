require 'rails_helper'
require "#{Rails.root}/lib/revision_analytics_service"

describe RevisionAnalyticsService do
  let!(:revision) do
    create(:revision, id: 1, user_id: 1, article_id: 1, date: 1.day.ago,
                      wp10: 60, ithenticate_id: r1_id)
  end

  let(:r1_id) { nil }

  let(:opts)       { {} }
  let(:course)     { create(:course, id: 10001, start: 1.month.ago, end: 1.month.from_now) }
  let(:user)       { create(:user, id: 1, wiki_id: 'Student_1') }
  let!(:c_user)    { create(:courses_user, user_id: user.id, course_id: course.id, role: 0) }
  let!(:article)   { create(:article, id: 1, title: 'Student_1/A_great_draft', namespace: 2) }
  let!(:revision5) do
    create(:revision, id: 5, user_id: 1, article_id: 1, date: 1.week.ago, wp10: 59)
  end

  let(:course2)    { create(:course, id: 10002, start: 1.month.ago, end: 1.month.from_now) }
  let(:user2)      { create(:user, id: 2, wiki_id: 'Student_2') }
  let!(:c_user2)   { create(:courses_user, user_id: user2.id, course_id: course2.id, role: 0) }
  let!(:article4)  { create(:article, id: 4, title: 'Student_2/Another_good_draft', namespace: 2) }
  let!(:revision4) do
    create(:revision, id: 4, user_id: 2, article_id: 4, date: 2.weeks.ago, wp10: 60)
  end

  # Articles/Revisions that should not show up
  let(:course3)    { create(:course, id: 10003, start: 1.month.ago, end: 1.month.from_now) }
  let(:user3)      { create(:user, id: 3, wiki_id: 'Student_3') }
  let!(:c_user3)   { create(:courses_user, user_id: user3.id, course_id: course3.id, role: 0) }

  let!(:article2)  { create(:article, id: 2, title: 'Student_3/A_poor_draft', namespace: 2) }
  let!(:revision2) do
    create(:revision, id: 2, user_id: 3, article_id: 2, date: 1.day.ago, wp10: 20)
  end

  let!(:article3)  { create(:article, id: 3, title: 'Student_3/An_old_draft', namespace: 2) }
  let!(:revision3) do
    create(:revision, id: 3, user_id: 3, article_id: 3,
                      date: 1.year.ago, wp10: 80, ithenticate_id: 5)
  end

  describe '#dyk_eligible' do
    subject { described_class.dyk_eligible(opts) }

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

    context '`scoped` param' do
      context 'article is in scope' do
        let(:opts) { { scoped: true, current_user: user } }
        it 'includes the article' do
          expect(subject).to include(article)
        end
      end
      context 'article is not in scope' do
        let(:user) { create(:user) }
        let(:opts) { { scoped: true, current_user: user } }
        it 'does not include the article' do
          expect(subject).not_to include(article)
        end
      end
    end
  end

  describe '.suspected_plagiarism' do
    context 'not scoped to current user' do
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
          expect(subject).to include(revision3)
        end
      end
    end

    context 'scoped to courses of current user' do
      subject { described_class.suspected_plagiarism(scoped: 'true', current_user: user) }
      let(:r1_id) { 5 }
      it 'should include a revision from their course' do
        expect(subject).to include(revision)
      end

      it 'should exlude a revision from outside their course' do
        expect(subject).not_to include(revision3)
      end
    end
  end

  describe '.recent_edits' do
    context 'not scoped to current user' do
      subject { described_class.recent_edits }
      it 'should return recent edits' do
        expect(subject).to include(revision)
        expect(subject).to include(revision2)
        expect(subject).to include(revision3)
      end
    end

    context 'not scoped to current user' do
      subject { described_class.recent_edits(scoped: 'true', current_user: user) }
      it 'should return recent edits from their course' do
        expect(subject).to include(revision)
      end
      it 'should exlude a edits from outside their course' do
        expect(subject).not_to include(revision2)
        expect(subject).not_to include(revision3)
      end
    end
  end
end
