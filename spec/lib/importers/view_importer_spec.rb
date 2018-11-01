# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/view_importer"

describe ViewImporter do
  before { stub_wiki_validation }

  describe '.update_views_for_article' do
    it 'does not fail if there are no revisions for an article' do
      VCR.use_cassette 'article/update_views_for_article' do
        article = create(:article,
                         id: 1,
                         title: 'Selfie',
                         namespace: 0,
                         views_updated_at: '2015-01-01')

        # Course and article-course are also needed.
        create(:course,
               id: 10001,
               start: Time.zone.today - 1.week,
               end: Time.zone.today + 1.week)
        create(:articles_course,
               id: 1,
               course_id: 10001,
               article_id: 1)

        described_class.new([article], true)
        described_class.new([article], false)
      end
    end
  end

  describe '.update_all_views' do
    let!(:course) do
      create(:course, id: 10001,
                      start: Time.zone.today - 1.week,
                      end: Time.zone.today + 1.week)
    end
    let!(:articles_course) { create(:articles_course, id: 1, course_id: 10001, article_id: 1) }
    let!(:revision) { create(:revision, article_id: 1) }
    let(:en_wiki) { Wiki.default_wiki }
    let(:es_wiki) { create(:wiki, id: 2, language: 'es', project: 'wikipedia') }

    it 'gets view data for all articles' do
      VCR.use_cassette 'article/update_all_views' do
        # Try it with no articles.
        described_class.update_all_views

        # Add an article (which has a revision and is part of the course)
        create(:article, id: 1, title: 'Wikipedia', namespace: 0,
                         wiki_id: en_wiki.id,
                         views_updated_at: Time.zone.today - 2.days)

        # Update again with this article.
        allow(WikiPageviews).to receive(:new).and_call_original
        described_class.update_all_views
      end
    end

    it 'works for non-default wikis' do
      # Wiki lookup happens in a Thread. We must fake the database lookup,
      # since the rspec database operations are done in-memory and are not
      # available in other threads.
      allow_any_instance_of(Article).to receive(:wiki).and_return(es_wiki)

      create(:article, id: 1, title: 'Wikipedia', namespace: 0,
                       wiki_id: es_wiki.id,
                       views_updated_at: Time.zone.today - 2.days)
      stub_request(:get, %r{.*pageviews/per-article/es.wikipedia.*})
        .to_return(
          status: 200,
          body: '{"items":[{"article":"Wikipedia","timestamp":"2017103100","views":6043}]}'
        )
      described_class.update_all_views
    end
  end

  describe '.update_new_views' do
    it 'gets view data for new articles' do
      VCR.use_cassette 'article/update_new_views' do
        # Try it with no articles.
        described_class.update_new_views

        # Add an article.
        create(:article,
               id: 1,
               title: 'Wikipedia',
               namespace: 0)

        # Course, article-course, and revision are also needed.
        create(:course,
               id: 10001,
               start: Time.zone.today - 1.month,
               end: Time.zone.today + 1.month)
        create(:articles_course,
               id: 1,
               course_id: 10001,
               article_id: 1)
        create(:revision,
               article_id: 1)

        # Update again with this article.
        described_class.update_new_views
        described_class.update_all_views
      end
    end
  end
end
