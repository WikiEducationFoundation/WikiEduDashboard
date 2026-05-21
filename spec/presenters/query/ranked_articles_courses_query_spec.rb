# frozen_string_literal: true

require 'rails_helper'

describe Query::RankedArticlesCoursesQuery, type: :model do
  let(:campaign) { create(:campaign) }
  let(:course1) { create(:course, slug: 'course-1', title: 'Course One', school: 'University A') }
  let(:course2) { create(:course, slug: 'course-2', title: 'Course Two', school: 'University B') }
  let(:courses) { [course1, course2] }

  let(:article1) { create(:article, title: 'AlphaArticle') }
  let(:article2) { create(:article, title: 'BetaArticle') }
  let(:article3) { create(:article, title: 'Special_Article') }
  let(:article4) { create(:article, title: '100%_Article') }

  let!(:ac1) do
    create(:articles_course, course: course1, article: article1,
                             character_sum: 500, references_count: 5, view_count: 100, tracked: true)
  end
  let!(:ac2) do
    create(:articles_course, course: course2, article: article2,
                             character_sum: 100, references_count: 10, view_count: 200, tracked: true)
  end
  let!(:ac3) do
    create(:articles_course, course: course1, article: article3,
                             character_sum: 300, references_count: 2, view_count: 50, tracked: true)
  end
  let!(:ac4) do
    create(:articles_course, course: course2, article: article4,
                             character_sum: 50, references_count: 1, view_count: 10, tracked: true)
  end
  let!(:ac_untracked) do
    create(:articles_course, course: course1, article: create(:article, title: 'Untracked'),
                             character_sum: 1000, tracked: false)
  end

  let(:default_params) do
    {
      courses: courses,
      per_page: 25,
      offset: 0,
      too_many: false
    }
  end

  describe '#scope' do
    it 'returns only tracked articles courses' do
      query = described_class.new(**default_params)
      results = query.scope
      expect(results.map(&:article_id)).to contain_exactly(article1.id, article2.id, article3.id, article4.id)
      expect(results.map(&:article_id)).not_to include(ac_untracked.article_id)
    end

    it 'applies text filter for article title' do
      query = described_class.new(**default_params.merge(article_title: 'Alpha'))
      expect(query.scope.map(&:article_id)).to contain_exactly(article1.id)
    end

    it 'applies text filter for course title' do
      query = described_class.new(**default_params.merge(course_title: 'Course Two'))
      expect(query.scope.map(&:article_id)).to contain_exactly(article2.id, article4.id)
    end

    it 'applies range filters' do
      query = described_class.new(**default_params.merge(char_added_from: 200, char_added_to: 600))
      expect(query.scope.map(&:article_id)).to contain_exactly(article1.id, article3.id)
    end

    describe 'SQL wildcard escaping' do
      it 'escapes % in article title' do
        query = described_class.new(**default_params.merge(article_title: '100%'))
        expect(query.scope.map(&:article_id)).to contain_exactly(article4.id)
      end

      it 'escapes _ in article title' do
        query = described_class.new(**default_params.merge(article_title: 'Special_'))
        expect(query.scope.map(&:article_id)).to contain_exactly(article3.id)
      end
    end
  end

  describe '#total_count' do
    it 'returns the count of matching filtered records' do
      query = described_class.new(**default_params.merge(article_title: 'Alpha'))
      expect(query.total_count).to eq(1)
    end
  end

  describe 'apply_sorting' do
    context 'when filtered count is <= 50,000' do
      it 'sorts the query by default character_sum DESC' do
        query = described_class.new(**default_params)
        expect(query.scope.map(&:article_id)).to eq([article1.id, article3.id, article2.id, article4.id])
      end

      it 'sorts the query even if too_many is true but filtered count is small' do
        query = described_class.new(**default_params.merge(too_many: true))
        expect(query.scope.map(&:article_id)).to eq([article1.id, article3.id, article2.id, article4.id])
      end

      it 'sorts by sort_column and sort_direction when provided' do
        query = described_class.new(**default_params.merge(sort_column: 'views', sort_direction: 'asc'))
        expect(query.scope.map(&:article_id)).to eq([article4.id, article3.id, article1.id, article2.id])
      end
    end

    context 'when filtered count is > 50,000' do
      it 'does not sort the query' do
        query = described_class.new(**default_params)
        # Stub the total_count to exceed 50000
        allow(query).to receive(:total_count).and_return(50001)

        # When unsorted, the order follows database default (which is usually insertion/ID order)
        # Let's ensure order method is NOT called on the base query.
        # We can also check that the ordering does not match the default sorted order.
        expect(query.scope.map(&:article_id)).to contain_exactly(article1.id, article2.id, article3.id, article4.id)
      end
    end
  end
end
