# frozen_string_literal: true

require 'rails_helper'
require_relative '../../app/presenters/courses_presenter'

describe CoursesPresenter do
  describe 'initialization via courses_list' do
    subject { described_class.new(current_user: nil, courses_list: Course.all) }

    let!(:course) { create(:course, user_count: 2, trained_count: 1) }

    it 'works with #courses, #active_courses, #user_count, #trained_count, #trained_percent' do
      expect(subject.courses.first).to eq(course)
      expect(subject.active_courses).not_to be_nil
      expect(subject.user_count).to eq(2)
      expect(subject.trained_count).to eq(1)
      expect(subject.trained_percent).to eq(50.0)
    end
  end

  describe '#campaign_articles' do
    subject do
      described_class.new(current_user: nil, campaign_param: Campaign.first.slug)
                     .campaign_articles
    end

    let(:article) { create(:article) }
    let(:article_two) { create(:article, title: 'Article_Two') }
    let(:course) { create(:course) }

    before do
      create(:articles_course, course:, article:, tracked: true)
      create(:articles_course, course:, article: article_two, tracked: false)
      course.campaigns << Campaign.first
    end

    it 'only includes tracked articles' do
      expect(subject[:articles_courses].count).to eq(1)
      expect(subject[:articles].first[1].title).to eq(article.title)
    end
  end

  describe 'the article pages' do
    let(:campaign) { create(:campaign) }
    let(:course) { create(:course) }
    let(:private_course) { create(:course, slug: 'Private/Course_(term)', private: true) }
    let(:page) { nil }
    let(:presenter) do
      described_class.new(current_user: nil, campaign_param: campaign.slug, page:)
    end

    before do
      create(:campaigns_course, campaign:, course:)
      create(:campaigns_course, campaign:, course: private_course)
      create(:articles_course, course:, article: create(:article), tracked: true)
      create(:articles_course, course: private_course, article: create(:article, title: 'Hidden'),
                               tracked: true)
    end

    it 'counts the articles of the courses it lists, so a private course adds no page' do
      expect(presenter.campaign_articles_count).to eq(1)
    end

    it 'reads the count from the cache' do
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      begin
        Rails.cache.write(campaign.articles_count_cache_key, 42)
        expect(presenter.campaign_articles_count).to eq(42)
      ensure
        Rails.cache = original_cache
      end
    end

    context 'with more articles than 200 pages hold' do
      before do
        allow(presenter).to receive(:campaign_articles_count).and_return(5001)
      end

      it 'links no page past the last one served' do
        pages = presenter.campaign_articles[:articles_courses]
        expect(pages.total_entries).to eq(5000)
        expect(pages.total_pages).to eq(200)
      end

      context 'on the last page served' do
        let(:page) { 200 }

        it 'says the list goes on' do
          expect(presenter.articles_list_truncated?).to be(true)
        end
      end

      context 'on the page before it' do
        let(:page) { 199 }

        it 'says nothing' do
          expect(presenter.articles_list_truncated?).to be(false)
        end
      end
    end

    context 'for a tag' do
      let(:presenter) do
        described_class.new(current_user: nil, tag: 'a_tag', courses_list: Course.all, page: 200)
      end

      before do
        allow(presenter).to receive(:tag_articles_count).and_return(5001)
      end

      it 'links no page past the last one served, and says the list goes on' do
        expect(presenter.campaign_articles.total_pages).to eq(200)
        expect(presenter.articles_list_truncated?).to be(true)
      end
    end
  end

  describe '#user_courses' do
    subject { described_class.new(current_user: user, campaign_param: campaign).user_courses }

    let(:admin) { create(:admin) }
    let(:campaign) { nil }

    context 'not signed in' do
      let(:user) { nil }

      it 'is nil' do
        expect(subject).to be_nil
      end
    end

    context 'not admin' do
      let(:user) { create(:test_user) }

      it 'is empty' do
        expect(subject).to be_empty
      end
    end

    context 'user is admin' do
      let!(:user) { admin }
      let!(:course)  { create(:course, end: Time.zone.today + 4.months) }
      let!(:c_user)  { create(:courses_user, course_id: course.id, user_id: user.id) }

      it 'returns the current and future courses for the user' do
        expect(subject).to include(course)
      end
    end
  end

  describe '#campaign' do
    subject { described_class.new(current_user: user, campaign_param:).campaign }

    let(:user) { create(:admin) }
    let(:campaign_param) { campaign_param }

    context 'campaigns' do
      context 'default campaign' do
        let(:campaign) { Campaign.find_by(slug: ENV['default_campaign']) }
        let(:default) { ENV['default_campaign'] }
        let(:campaign_param) { default }

        it 'returns default campaign' do
          expect(subject).to eq(campaign)
        end
      end

      context 'valid campaign' do
        let!(:campaign) { create(:campaign, slug: 'foo') }
        let(:campaign_param) { campaign.slug }

        it 'returns that campaign' do
          expect(subject).to eq(campaign)
        end
      end

      context 'invalid campaign' do
        let(:campaign_param) { 'lolfakecampaign' }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end
    end
  end

  describe 'searching campaign' do
    subject { described_class.new(current_user: nil, courses_list: Course.all) }

    let!(:course) do
      create(:course, id: 3, title: 'Math Foundations of Informatics',
                      school: 'Indiana University', term: 'Fall 2017')
    end

    let!(:user) { create(:user, username: 'ragesoss', id: 666, trained: true) }

    let!(:courses_user) do
      create(:courses_user,
             id: 1,
             course_id: 3,
             user_id: 666,
             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end

    context 'find course based on title' do
      it 'returns courses when searching' do
        search = 'informatics'
        expect(subject.search_courses(search)).not_to be_empty
      end
    end

    context 'find course based on school' do
      it 'returns courses when searching' do
        search = 'indiana'
        expect(subject.search_courses(search)).not_to be_empty
      end
    end

    context 'find course based on term' do
      it 'returns courses when searching' do
        search = 'fall'
        expect(subject.search_courses(search)).not_to be_empty
      end
    end

    context 'find course based on instructor' do
      it 'returns courses when searching' do
        search = 'rage'
        expect(subject.search_courses(search)).not_to be_empty
      end
    end
  end
end
