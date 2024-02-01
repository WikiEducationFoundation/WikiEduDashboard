# frozen_string_literal: true
# == Schema Information
#
# Table name: revisions
#
#  id                :integer          not null, primary key
#  characters        :integer          default(0)
#  created_at        :datetime
#  updated_at        :datetime
#  user_id           :integer
#  article_id        :integer
#  views             :bigint           default(0)
#  date              :datetime
#  new_article       :boolean          default(FALSE)
#  deleted           :boolean          default(FALSE)
#  wp10              :float(24)
#  wp10_previous     :float(24)
#  system            :boolean          default(FALSE)
#  ithenticate_id    :integer
#  wiki_id           :integer
#  mw_rev_id         :integer
#  mw_page_id        :integer
#  features          :text(65535)
#  features_previous :text(65535)
#  summary           :text(65535)
#

require 'rails_helper'

describe Revision, type: :model do
  describe '#references_added' do
    let(:reference_count_key) { 'num_ref' }
    let(:refs_tags_key) { 'feature.wikitext.revision.ref_tags' }
    let(:wikidata_refs_tags_key) { 'feature.len(<datasource.wikidatawiki.revision.references>)' }
    let(:shortened_refs_tags_key) { 'feature.enwiki.revision.shortened_footnote_templates' }
    let(:enwikidata) { create(:wiki, project: 'wikidata', language: 'en') }

    context 'new article' do
      let(:mw_rev_id) { 95249249 }

      before do
        stub_wiki_validation
        create(:revision,
               mw_rev_id:,
               article_id: 45010238,
               mw_page_id: 45010238)
        create(:revision,
               mw_rev_id: 95249256,
               article_id: 36612,
               mw_page_id: 36612,
               wiki_id: enwikidata.id)
      end

      it 'returns zero' do
        val = described_class.find_by(mw_rev_id: 95249249).references_added
        wikidata_val = described_class.find_by(mw_rev_id: 95249256).references_added
        expect(val).to eq(0)
        expect(wikidata_val).to eq(0)
      end
    end

    context 'First revision' do
      let(:mw_rev_id) { 857571904 }

      before do
        stub_wiki_validation
        create(:revision,
               mw_rev_id:,
               article_id: 90010238,
               mw_page_id: 90010238,
               new_article: true,
               features: {
                 refs_tags_key => 10
               })
        create(:revision,
               mw_rev_id: 840608564,
               article_id: 41155,
               mw_page_id: 41155,
               wiki_id: enwikidata.id,
               new_article: true,
               features: {
                 wikidata_refs_tags_key => 10
               })
      end

      it 'returns no. of references added' do
        val = described_class.find_by(mw_rev_id: 857571904).references_added
        wikidata_val = described_class.find_by(mw_rev_id: 840608564).references_added
        expect(val).to eq(10)
        expect(wikidata_val).to eq(10)
      end
    end

    context 'Not the first revision, but previous revision data is not available' do
      let(:mw_rev_id) { 89023457 }

      before do
        stub_wiki_validation
        create(:revision,
               mw_rev_id:,
               mw_page_id: 78240014,
               article_id: 78240014,
               new_article: false,
               features: {
                 refs_tags_key => 10
               })

        create(:revision,
               mw_rev_id: 89023158,
               mw_page_id: 328439,
               article_id: 328439,
               wiki_id: enwikidata.id,
               new_article: false,
               features: {
                 wikidata_refs_tags_key => 10
               })
      end

      it 'returns 0 references added' do
        val = described_class.find_by(mw_rev_id: 89023457).references_added
        wikidata_val = described_class.find_by(mw_rev_id: 89023158).references_added
        expect(val).to eq(0)
        expect(wikidata_val).to eq(0)
      end
    end

    context 'Deleted some references' do
      let(:mw_rev_id) { 852178130 }

      before do
        stub_wiki_validation
        create(:revision,
               mw_rev_id:,
               article_id: 79010238,
               mw_page_id: 79010238,
               features: {
                 refs_tags_key => 0
               },
               features_previous: {
                 refs_tags_key => 6
               })
        create(:revision,
               mw_rev_id: 852178131,
               article_id: 320317,
               mw_page_id: 320317,
               wiki_id: enwikidata.id,
               features: {
                 wikidata_refs_tags_key => 0
               },
               features_previous: {
                 wikidata_refs_tags_key => 6
               })
      end

      it 'Would be negative' do
        val = described_class.find_by(mw_rev_id: 852178130).references_added
        wikidata_val = described_class.find_by(mw_rev_id: 852178131).references_added
        expect(val).to eq(-6)
        expect(wikidata_val).to eq(-6)
      end
    end

    context 'New refernces are added and not a new article' do
      let(:mw_rev_id) { 870348507 }

      before do
        stub_wiki_validation
        create(:revision,
               mw_rev_id:,
               article_id: 55010239,
               mw_page_id: 55010239,
               features: {
                 refs_tags_key => 22
               },
               features_previous: {
                 refs_tags_key => 17
               })
        create(:revision,
               mw_rev_id: 870348508,
               article_id: 55010239,
               mw_page_id: 55010239,
               wiki_id: enwikidata.id,
               features: {
                 wikidata_refs_tags_key => 22
               },
               features_previous: {
                 wikidata_refs_tags_key => 17
               })
      end

      it 'returns positive value' do
        val = described_class.find_by(mw_rev_id: 870348507).references_added
        wikidata_val = described_class.find_by(mw_rev_id: 870348508).references_added
        expect(val).to eq(5)
        expect(wikidata_val).to eq(5)
      end
    end

    context 'has shortened footnote templates' do
      let(:mw_rev_id) { 902872698 }

      before do
        stub_wiki_validation
        create(:revision,
               mw_rev_id:,
               article_id: 55012289,
               mw_page_id: 55012289,
               features: {
                 refs_tags_key => 4,
                 shortened_refs_tags_key => 131
               },
               features_previous: {
                 refs_tags_key => 0,
                 shortened_refs_tags_key => 1
               })
      end

      it 'includes the shortened footnote template references' do
        val = described_class.find_by(mw_rev_id: 902872698).references_added
        expect(val).to eq(134)
      end
    end

    context 'has reference count key set as nil' do
      let(:mw_rev_id) { 902872698 }

      before do
        stub_wiki_validation
        create(:revision,
               mw_rev_id:,
               article_id: 55012289,
               mw_page_id: 55012289,
               features: {
                 reference_count_key => nil,
                 refs_tags_key => 56
               },
               features_previous: {
                 reference_count_key => nil,
                 refs_tags_key => 7
               })
      end

      it 'uses the ref tag from Lift Wing API' do
        val = described_class.find_by(mw_rev_id: 902872698).references_added
        expect(val).to eq(49)
      end
    end

    context 'has complete features' do
      let(:mw_rev_id) { 902872698 }

      before do
        stub_wiki_validation
        create(:revision,
               mw_rev_id:,
               article_id: 55012289,
               mw_page_id: 55012289,
               features: {
                 reference_count_key => 57,
                 refs_tags_key => 56,
                 shortened_refs_tags_key => 14
               },
               features_previous: {
                 reference_count_key => 6,
                 refs_tags_key => 7,
                 shortened_refs_tags_key => 1
               })
      end

      it 'uses the reference count key from reference-counter API' do
        val = described_class.find_by(mw_rev_id: 902872698).references_added
        expect(val).to eq(51)
      end
    end
  end

  describe '#update' do
    it 'updates a revision with new data' do
      revision = build(:revision,
                       id: 1,
                       article_id: 1,
                       views: 1000)
      revision.update(
        user_id: 1,
        views: 9000
      )
      expect(revision.views).to eq(9000)
      expect(revision.user_id).to eq(1)
    end
  end

  describe '#url' do
    let(:article) { create(:article, title: 'Vectors_in_gene_therapy') }
    let(:talk_page) { create(:article, title: 'Selfie', namespace: Article::Namespaces::TALK) }

    it 'returns a diff url for the revision' do
      revision = create(:revision,
                        mw_rev_id: 637221390,
                        article_id: article.id)
      url = revision.url
      expect(url).to eq('https://en.wikipedia.org/w/index.php?title=Vectors_in_gene_therapy&diff=prev&oldid=637221390')
    end

    it 'includes the prefix for non-mainspace articles' do
      revision = create(:revision,
                        mw_rev_id: 637221390,
                        article_id: talk_page.id)
      url = revision.url
      expect(url).to eq('https://en.wikipedia.org/w/index.php?title=Talk:Selfie&diff=prev&oldid=637221390')
    end
  end

  describe '#infer_courses_from_user' do
    subject { revision.infer_courses_from_user }

    let!(:user)         { create(:user) }
    let!(:article)      { create(:article) }
    let!(:revision) do
      create(:revision, article_id: article.id, user_id: user.id, date: Time.zone.today)
    end
    let!(:course)       { create(:course, start: course_start, end: course_end) }
    let!(:courses_user) { create(:courses_user, course_id: course.id, user_id: user.id) }
    let(:course_start)  { revision.created_at - 3.days }
    let(:course_end)    { revision.date + 3.days }

    context 'one course' do
      it 'returns the course record we assume the user was in when they made the revision' do
        expect(subject).to include(course)
      end
    end

    context 'two courses' do
      let!(:course2)       { create(:course, start: course_start, end: course_end, slug: 'foo/2') }
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
