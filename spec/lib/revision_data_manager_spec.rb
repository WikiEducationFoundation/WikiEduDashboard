# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/revision_data_manager"
require "#{Rails.root}/lib/articles_courses_cleaner"

describe RevisionDataManager do
  describe '#fetch_revision_data_for_course' do
    let(:course) { create(:course, start: '2018-01-01', end: '2018-12-31') }
    let(:user) { create(:user, username: 'Ragesoss') }
    let(:home_wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
    let(:instance_class) { described_class.new(home_wiki, course) }
    let(:subject) do
      instance_class.fetch_revision_data_for_course('20180706', '20180707')
    end
    let(:revision_data) do
      [{ 'mw_page_id' => '55345266',
      'wiki_id' => 1,
      'title' => 'Ragesoss/citing_sources',
      'namespace' => '2' }]
    end
    let(:revision_data2) do
      [{ 'mw_page_id' => '777',
      'wiki_id' => 1,
      'title' => 'Ragesoss/citing_sources',
      'namespace' => '4' },
       { 'mw_page_id' => '123',
       'wiki_id' => 1,
       'title' => 'Draft article',
       'namespace' => '118' }]
    end
    let(:sub_data) { [data1, data2] }
    let(:data1) do
      [
        '112',
        {
          'article' => {
            'mw_page_id' => '777',
            'title' => 'Ragesoss/citing_sources',
            'namespace' => '4',
            'wiki_id' => 1
          },
          'revisions' => [
            { 'mw_rev_id' => '849116430', 'date' => '20180706', 'characters' => '569',
              'mw_page_id' => '777', 'username' => 'Ragesoss', 'new_article' => 'false',
              'system' => 'false', 'wiki_id' => 1 }
          ]
        }
      ]
    end
    let(:data2) do
      [
        '789',
        {
          'article' => {
            'mw_page_id' => '123',
            'title' => 'Draft article',
            'namespace' => '118',
            'wiki_id' => 1
          },
          'revisions' => [
            { 'mw_rev_id' => '456', 'date' => '20180706', 'characters' => '569',
              'mw_page_id' => '123', 'username' => 'Ragesoss', 'new_article' => 'false',
              'system' => 'false', 'wiki_id' => 1 }
          ]
        }
      ]
    end
    let(:filtered_sub_data) { [data1] }

    before do
      create(:courses_user, course:, user:)
    end

    it 'fetches all the revisions that occurred during the given period of time' do
      VCR.use_cassette 'revision_importer/all' do
        revisions = subject
        expect(revisions.length).to eq(4)
        # Fetches the right revision ids
        expect(revisions[0].mw_rev_id).to eq(849116430)
        expect(revisions[1].mw_rev_id).to eq(849116480)
        expect(revisions[2].mw_rev_id).to eq(849116533)
        expect(revisions[3].mw_rev_id).to eq(849116572)

        # Fetches the scores
        expect(revisions[0].wp10).to be_within(0.01).of(18.29)
        expect(revisions[0].wp10_previous).to be_within(0.01).of(11.96)
        expect(revisions[0].features).to eq({ 'num_ref' => 2 })
        expect(revisions[0].features_previous).to eq({ 'num_ref' => 2 })
        expect(revisions[0].deleted).to eq(false)

        expect(revisions[1].wp10).to be_within(0.01).of(20.09)
        expect(revisions[1].wp10_previous).to be_within(0.01).of(18.29)
        expect(revisions[1].features).to eq({ 'num_ref' => 3 })
        expect(revisions[1].features_previous).to eq({ 'num_ref' => 2 })
        expect(revisions[1].deleted).to eq(false)

        expect(revisions[2].wp10).to be_within(0.01).of(21.37)
        expect(revisions[2].wp10_previous).to be_within(0.01).of(20.09)
        expect(revisions[2].features).to eq({ 'num_ref' => 3 })
        expect(revisions[2].features_previous).to eq({ 'num_ref' => 3 })
        expect(revisions[2].deleted).to eq(false)

        expect(revisions[3].wp10).to be_within(0.01).of(21.34)
        expect(revisions[3].wp10_previous).to be_within(0.01).of(21.37)
        expect(revisions[3].features).to eq({ 'num_ref' => 3 })
        expect(revisions[3].features_previous).to eq({ 'num_ref' => 3 })
        expect(revisions[3].deleted).to eq(false)
      end
    end

    it 'only calculates revisions scores for articles in mainspace, userspace or draftspace' do
      allow(instance_class).to receive(:get_revisions).and_return([data1, data2])
      VCR.use_cassette 'revision_importer/all' do
        revisions = subject
        # Returns all revisions
        expect(revisions.length).to eq(2)
        # Only the one in mainspace has scores
        expect(revisions[0].features).to eq({})
        expect(revisions[1].features).to eq({ 'num_ref' => 0 })
      end
    end

    it 'calls ArticeImporter as side effect' do
      expect_any_instance_of(ArticleImporter).to receive(:import_articles_from_revision_data)
        .once
        .with(revision_data)

      VCR.use_cassette 'revision_importer/all' do
        subject
      end
    end

    it 'creates articles for all revisions even for article scoped programs' do
      allow_any_instance_of(described_class).to receive(:get_course_revisions)
        .and_return([sub_data, filtered_sub_data])

      article_importer = instance_double(ArticleImporter)
      allow(ArticleImporter).to receive(:new).and_return(article_importer)

      expect(article_importer).to receive(:import_articles_from_revision_data)
        .once
        .with(revision_data2)

      subject
    end
  end

  describe '#fetch_revision_data_for_users' do
    let(:course) { create(:course, start: '2018-01-01', end: '2018-12-31') }
    let(:user1) { create(:user, username: 'HonorsCJ') }
    let(:user2) { create(:user, username: 'Kh16897') }
    let(:users) { [user1, user2] }
    let(:home_wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
    let(:instance_class) { described_class.new(home_wiki, course) }
    let(:subject) do
      instance_class.fetch_revision_data_for_users(users, '20240820000000', '20240830235959')
    end

    it 'fetches all the revisions for the specific users during the given period of time' do
      VCR.use_cassette 'revision_importer/all' do
        revisions = subject
        expect(revisions.length).to eq(10)
        # Revisions don't have scores
        expect(revisions[0].wp10).to eq(nil)
        expect(revisions[0].features).to eq({})
      end
    end
  end
end
