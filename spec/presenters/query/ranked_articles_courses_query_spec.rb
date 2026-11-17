# frozen_string_literal: true

require 'rails_helper'

describe Query::RankedArticlesCoursesQuery do
  let(:course) { create(:course) }
  let(:kept) { create(:article, title: 'Kept') }
  let(:deleted) { create(:article, title: 'Deleted', deleted: true) }
  let(:query) do
    described_class.new(courses: Course.where(id: course.id), per_page: 25, offset: 0,
                        too_many: false, sort_column:, sort_direction:)
  end
  let(:sort_column) { nil }
  let(:sort_direction) { nil }

  before do
    create(:articles_course, course:, article: deleted, tracked: true, character_sum: 500)
    create(:articles_course, course:, article: kept, tracked: true, character_sum: 100)
  end

  it 'ranks an article ahead of a deleted one, whatever their characters' do
    expect(query.scope.map(&:article_id)).to eq([kept.id, deleted.id])
  end

  context 'sorted by title' do
    let(:sort_column) { 'title' }
    let(:sort_direction) { 'asc' }

    it 'ranks by the title' do
      expect(query.scope.map(&:article_id)).to eq([deleted.id, kept.id])
    end
  end

  context 'sorted by views' do
    let(:sort_column) { 'view_sum' }
    let(:sort_direction) { 'desc' }
    let(:recent) { create(:article, title: 'Recent', average_views: 1.0) }
    let(:inherited) { create(:article, title: 'Inherited', average_views: 4.0) }
    let(:historical) { create(:article, title: 'Historical') }

    before do
      # 10 days at 5 views a day; the articles_courses average wins over the article's
      create(:articles_course, course:, article: recent, tracked: true,
                               first_revision: 10.days.ago, average_views: 5.0)
      # 100 days at the article's 4 views a day, there being no articles_courses average
      create(:articles_course, course:, article: inherited, tracked: true,
                               first_revision: 100.days.ago)
      # no first revision, so the stored view_count stands in
      create(:articles_course, course:, article: historical, tracked: true, view_count: 120)
    end

    it 'ranks by the views the page shows, not by a column' do
      expect(query.scope.map(&:article_id).first(3))
        .to eq([inherited.id, historical.id, recent.id])
    end

    context 'ascending' do
      let(:sort_direction) { 'asc' }

      it 'ranks the fewest views first' do
        expect(query.scope.map(&:article_id).last(3))
          .to eq([recent.id, historical.id, inherited.id])
      end
    end
  end

  context 'with a direction that is not asc or desc' do
    let(:sort_column) { 'title' }
    let(:sort_direction) { 'sideways' }

    it 'keeps the default order' do
      expect(query.scope.map(&:article_id)).to eq([kept.id, deleted.id])
    end
  end

  it 'defers only the id to the ranking subquery, not every articles column' do
    sql = query.scope.to_sql
    expect(sql).to include('INNER JOIN (SELECT `articles_courses`.`id` FROM `articles_courses`')
    expect(sql).not_to include('`articles`.`title` AS')
  end
end
