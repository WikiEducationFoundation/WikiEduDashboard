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

  it 'defers only the id to the ranking subquery, not every articles column' do
    sql = query.scope.to_sql
    expect(sql).to include('INNER JOIN (SELECT `articles_courses`.`id` FROM `articles_courses`')
    expect(sql).not_to include('`articles`.`title` AS')
  end
end
