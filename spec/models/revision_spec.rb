# == Schema Information
#
# Table name: revisions
#
#  id             :integer          not null, primary key
#  characters     :integer          default(0)
#  created_at     :datetime
#  updated_at     :datetime
#  user_id        :integer
#  article_id     :integer
#  views          :integer          default(0)
#  date           :datetime
#  new_article    :boolean          default(FALSE)
#  deleted        :boolean          default(FALSE)
#  system         :boolean          default(FALSE)
#  wp10           :float(24)
#  wp10_previous  :float(24)
#  ithenticate_id :integer
#  report_url     :string(255)
#  wiki_id        :integer
#  mw_rev_id      :integer
#  mw_page_id     :integer
#

require 'rails_helper'

describe Revision do
  describe '#update' do
    it 'should update a revision with new data' do
      revision = build(:revision,
                       id: 1,
                       article_id: 1,
                       views: 1000)
      revision.update(
        user_id: 1,
        views: 9000)
      expect(revision.views).to eq(9000)
      expect(revision.user_id).to eq(1)
    end
  end

  describe '#url' do
    it 'should generate a diff url for the revision' do
      create(:article,
             id: 1,
             title: 'Vectors_in_gene_therapy')
      create(:revision,
             id: 637221390,
             article_id: 1)
      url = Revision.find(637221390).url
      expect(url).to eq('https://en.wikipedia.org/w/index.php?title=Vectors_in_gene_therapy&diff=prev&oldid=637221390')
    end
  end

  describe '#infer_courses_from_user' do
    let!(:user)         { create(:user) }
    let!(:article)      { create(:article) }
    let!(:revision) do
      create(:revision, article_id: article.id, user_id: user.id, date: Time.zone.today)
    end
    let!(:course)       { create(:course, start: course_start, end: course_end) }
    let!(:courses_user) { create(:courses_user, course_id: course.id, user_id: user.id) }
    let(:course_start)  { revision.created_at - 3.days }
    let(:course_end)    { revision.date + 3.days }

    subject { revision.infer_courses_from_user }

    context 'one course' do
      it 'returns the course record we assume the user was in when they made the revision' do
        expect(subject).to include(course)
      end
    end

    context 'two courses' do
      let!(:course2)       { create(:course, start: course_start, end: course_end) }
      let!(:courses_user2) { create(:courses_user, course_id: course2.id, user_id: user.id) }
      it 'returns the course records for the user; we do not know which course it was for' do
        expect(subject).to include(course)
        expect(subject).to include(course2)
      end
    end
  end

  describe '#plagiarism_report_link' do
    context 'when ithenticate id is present' do
      let(:revision) { create(:revision, ithenticate_id: 123) }
      it 'returns a url that includes the ithenticate id' do
        expect(revision.plagiarism_report_link).to include('123')
      end
    end

    context 'when ithenticate id is nil' do
      let(:revision) { create(:revision, ithenticate_id: nil) }
      it 'returns nil' do
        expect(revision.plagiarism_report_link).to be_nil
      end
    end
  end
end
