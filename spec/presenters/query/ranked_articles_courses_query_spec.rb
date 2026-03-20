# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../app/presenters/query/ranked_articles_courses_query'

describe Query::RankedArticlesCoursesQuery do
  let(:course) { create(:course) }
  let(:article) { create(:article) }
  let(:article_two) { create(:article, title: 'Second Article') }

  let!(:ac_one) do
    create(:articles_course, course:, article:, tracked: true,
                              character_sum: 500, references_count: 3, view_count: 100)
  end
  let!(:ac_two) do
    create(:articles_course, course:, article: article_two, tracked: true,
                              character_sum: 200, references_count: 10, view_count: 50)
  end
  # Untracked — should never appear in results
  let!(:ac_untracked) do
    create(:articles_course, course:, article: create(:article, title: 'Untracked'),
                              tracked: false)
  end

  let(:courses) { Course.where(id: course.id) }

  def build_query(**overrides)
    described_class.new(
      courses:,
      per_page: 25,
      offset: 0,
      too_many: false,
      **overrides
    )
  end

  describe '#scope' do
    it 'returns only tracked articles_courses for the given courses' do
      result_ids = build_query.scope.map(&:article_id)
      expect(result_ids).to contain_exactly(article.id, article_two.id)
    end

    it 'does not include untracked articles' do
      result_ids = build_query.scope.map(&:article_id)
      expect(result_ids).not_to include(ac_untracked.article_id)
    end

    it 'respects pagination offset' do
      result = described_class.new(courses:, per_page: 1, offset: 1, too_many: false).scope
      expect(result.length).to eq(1)
    end
  end

  describe 'text filters' do
    describe 'article_title filter' do
      it 'returns only articles matching the title' do
        result = build_query(article_title: 'Second').scope
        expect(result.map(&:article_id)).to contain_exactly(article_two.id)
      end

      it 'is case-insensitive via LIKE' do
        result = build_query(article_title: article.title.downcase).scope
        expect(result.map(&:article_id)).to include(article.id)
      end
    end

    describe 'course_title filter' do
      it 'returns only articles from courses matching the title' do
        result = build_query(course_title: course.title).scope
        expect(result.map(&:article_id)).to contain_exactly(article.id, article_two.id)
      end

      it 'returns nothing when the title does not match any course' do
        result = build_query(course_title: 'no_such_course').scope
        expect(result).to be_empty
      end
    end

    describe 'school filter' do
      it 'returns only articles from courses at that school' do
        result = build_query(school: course.school).scope
        expect(result.map(&:article_id)).to contain_exactly(article.id, article_two.id)
      end

      it 'returns nothing when the school does not match' do
        result = build_query(school: 'Nonexistent University').scope
        expect(result).to be_empty
      end
    end
  end

  describe 'range filters' do
    describe 'char_added_from / char_added_to' do
      it 'filters by minimum characters added' do
        result = build_query(char_added_from: 400).scope
        expect(result.map(&:article_id)).to contain_exactly(article.id)
      end

      it 'filters by maximum characters added' do
        result = build_query(char_added_to: 300).scope
        expect(result.map(&:article_id)).to contain_exactly(article_two.id)
      end

      it 'filters by a range of characters added' do
        result = build_query(char_added_from: 100, char_added_to: 300).scope
        expect(result.map(&:article_id)).to contain_exactly(article_two.id)
      end
    end

    describe 'references_count_from / references_count_to' do
      it 'filters by minimum references' do
        result = build_query(references_count_from: 5).scope
        expect(result.map(&:article_id)).to contain_exactly(article_two.id)
      end

      it 'filters by maximum references' do
        result = build_query(references_count_to: 4).scope
        expect(result.map(&:article_id)).to contain_exactly(article.id)
      end
    end

    describe 'view_count_from / view_count_to' do
      it 'filters by minimum view count' do
        result = build_query(view_count_from: 75).scope
        expect(result.map(&:article_id)).to contain_exactly(article.id)
      end

      it 'filters by maximum view count' do
        result = build_query(view_count_to: 75).scope
        expect(result.map(&:article_id)).to contain_exactly(article_two.id)
      end
    end
  end

  describe 'sorting' do
    context 'when too_many is true' do
      it 'applies no ORDER clause' do
        query = described_class.new(courses:, per_page: 25, offset: 0, too_many: true)
        sql = query.scope.to_sql
        # The subquery driving the deferred join has no ORDER BY
        expect(sql).not_to include('ORDER')
      end
    end

    context 'with sort_column and sort_direction' do
      it 'sorts by char_added descending' do
        result = build_query(sort_column: 'char_added', sort_direction: 'DESC').scope
        char_sums = result.map(&:character_sum)
        expect(char_sums).to eq(char_sums.sort.reverse)
      end

      it 'sorts by references ascending' do
        result = build_query(sort_column: 'references', sort_direction: 'ASC').scope
        refs = result.map(&:references_count)
        expect(refs).to eq(refs.sort)
      end

      it 'sorts by view_count descending' do
        result = build_query(sort_column: 'views', sort_direction: 'DESC').scope
        views = result.map(&:view_count)
        expect(views).to eq(views.sort.reverse)
      end
    end

    context 'with no sort_column specified' do
      it 'falls back to character_sum DESC' do
        result = build_query.scope
        char_sums = result.map(&:character_sum)
        expect(char_sums).to eq(char_sums.sort.reverse)
      end
    end
  end
end
