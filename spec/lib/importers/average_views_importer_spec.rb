# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/average_views_importer"

describe AverageViewsImporter do
  let(:article) { create(:article, title: 'Selfie') }
  let(:article4) { create(:article, title: 'Mathematics') }
  let(:course) { create(:course) }

  let(:articles_course) do
    create(:articles_course, course:, article_id: article.id, average_views: 1,
    average_views_updated_at: 1.day.ago, first_revision: 10.days.ago)
  end

  let(:article_course_with_insufficient_rev_time) do
    create(:articles_course, course:, article_id: article4.id, average_views: 10,
           average_views_updated_at: 1.day.ago, first_revision: 1.day.ago)
  end

  before do
    travel_to Date.new(2025, 8, 28)
    articles_course
    article_course_with_insufficient_rev_time
  end

  after do
    travel_back
  end

  describe '.update_average_views' do
    it 'saves average page views on ArticlesCourses records' do
      VCR.use_cassette 'average_views' do
        described_class.update_average_views(ArticlesCourses.all)
      end
      expect(articles_course.reload.average_views).to be > 50
    end

    it 'does not save average views when insufficient time has passed since first revision' do
      VCR.use_cassette 'average_views' do
        described_class.update_average_views(ArticlesCourses.all)
      end
      expect(article_course_with_insufficient_rev_time.reload.average_views).to eq(10)
    end
  end

  describe '.update_outdated_average_views' do
    let!(:article1) do
      create(:article, title: 'Petrichor')
    end

    let!(:article_course_never_updated) do
      create(:articles_course, course:, article_id: article1.id,
      average_views: 0, average_views_updated_at: nil, first_revision: 10.days.ago)
    end

    let(:article2) do
      create(:article, title: 'ObsoleteTech')
    end

    let!(:article_course_very_old) do
      create(:articles_course, course:, article_id: article2.id, average_views: 1,
      average_views_updated_at: 2.months.ago, first_revision: 10.days.ago)
    end

    let(:article3) { create(:article, title: 'History') }

    let!(:article_without_first_revision) do
      create(:articles_course, course:, article_id: article3.id)
    end

    it 'does not update recently-updated records' do
      VCR.use_cassette 'average_views' do
        described_class.update_outdated_average_views(course)
      end
      expect(articles_course.reload.average_views).to eq(1)
      expect(article_course_never_updated.reload.average_views).to be > 1300
      expect(article_course_very_old.reload.average_views).to eq(0)
    end

    it 'does not update AC record if no first_revision' do
      VCR.use_cassette 'average_views' do
        described_class.update_outdated_average_views(course)
      end
      expect(article_without_first_revision.reload.average_views).to be_nil
      expect(article_without_first_revision.reload.average_views_updated_at).to be_nil
    end
  end
end
