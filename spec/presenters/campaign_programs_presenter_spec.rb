# frozen_string_literal: true

require 'rails_helper'
require_relative '../../app/presenters/campaign_programs_presenter'

describe CampaignProgramsPresenter do
  let(:courses) { Course.all }
  let(:page) { 1 }
  let(:sort_column) { 'title' }
  let(:sort_direction) { 'ASC' }

  subject(:presenter) do
    described_class.new(
      courses:,
      page:,
      sort_column:,
      sort_direction:
    )
  end

  let!(:course) do
    create(:course, title: 'Test Course',
                    school: 'Test School',
                    term: 'Test Term',
                    user_count: 5,
                    character_sum: 1000,
                    references_count: 50,
                    view_sum: 200,
                    recent_revision_count: 10)
  end

  let(:instructor) { create(:user, username: 'test_instructor') }

  before do
    create(:courses_user, course:, user: instructor,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  describe '#build_search_terms' do
    it 'returns empty string when no filters' do
      expect(presenter.build_search_terms({})).to eq('')
    end

    it 'includes title_query when present' do
      filters = { title_query: 'test' }
      expect(presenter.build_search_terms(filters)).to include('title: test')
    end

    it 'includes school when present' do
      filters = { school: 'university' }
      expect(presenter.build_search_terms(filters)).to include('school: university')
    end

    it 'includes range filters when present' do
      filters = { revisions_min: '5', revisions_max: '20' }
      expect(presenter.build_search_terms(filters)).to eq('revisions: 5 - 20')
    end

    it 'only includes min when max is blank' do
      filters = { revisions_min: '5', revisions_max: '' }
      expect(presenter.build_search_terms(filters)).to eq('revisions: 5 - ')
    end

    it 'only includes max when min is blank' do
      filters = { revisions_min: '', revisions_max: '20' }
      expect(presenter.build_search_terms(filters)).to eq('revisions:  - 20')
    end

    it 'includes multiple range filters' do
      filters = {
        revisions_min: '5',
        revisions_max: '20',
        word_count_min: '100',
        word_count_max: '500'
      }
      terms = presenter.build_search_terms(filters)
      expect(terms).to include('revisions: 5 - 20')
      expect(terms).to include('word_count: 100 - 500')
    end
  end

  describe '#filter_courses' do
    it 'returns courses' do
      results = presenter.filter_courses({})
      expect(results).to be_a(ActiveRecord::Relation)
      expect(results).to include(course)
    end

    it 'filters by title query' do
      results = presenter.filter_courses({ title_query: 'Test' })
      expect(results).to include(course)
    end

    it 'filters by school' do
      results = presenter.filter_courses({ school: 'Test School' })
      expect(results).to include(course)
    end

    it 'filters by revisions range' do
      results = presenter.filter_courses({ revisions_min: '5', revisions_max: '20' })
      expect(results).to include(course)
    end

    it 'filters by word_count range' do
      results = presenter.filter_courses({ word_count_min: '100', word_count_max: '300' })
      expect(results).to include(course)
    end

    it 'filters by references range' do
      results = presenter.filter_courses({ references_min: '25', references_max: '100' })
      expect(results).to include(course)
    end

    it 'filters by views range' do
      results = presenter.filter_courses({ views_min: '100', views_max: '500' })
      expect(results).to include(course)
    end

    it 'filters by editors range' do
      results = presenter.filter_courses({ users_min: '2', users_max: '10' })
      expect(results).to include(course)
    end

    it 'filters by creation date range' do
      results = presenter.filter_courses({
        creation_start: course.created_at.strftime('%Y-%m-%d'),
        creation_end: (course.created_at + 1.day).strftime('%Y-%m-%d')
      })
      expect(results).to include(course)
    end

    it 'filters by start date range' do
      results = presenter.filter_courses({
        start_date_start: course.start.strftime('%Y-%m-%d'),
        start_date_end: (course.start + 1.day).strftime('%Y-%m-%d')
      })
      expect(results).to include(course)
    end

    it 'combines multiple filters' do
      results = presenter.filter_courses({
        title_query: 'Test',
        school: 'Test School',
        revisions_min: '5'
      })
      expect(results).to include(course)
    end

    it 'returns empty when no matches' do
      results = presenter.filter_courses({ title_query: 'Nonexistent Course' })
      expect(results).to be_empty
    end

    it 'handles invalid integer gracefully' do
      results = presenter.filter_courses({ revisions_min: 'not_a_number' })
      expect(results).to include(course)
    end

    it 'handles invalid date gracefully' do
      results = presenter.filter_courses({ creation_start: 'invalid_date' })
      expect(results).to include(course)
    end
  end

  describe '#courses_order_clause' do
    context 'when sort params are present' do
      let(:sort_column) { 'school' }
      let(:sort_direction) { 'DESC' }

      it 'builds order clause with secondary title sort' do
        expect(presenter.send(:courses_order_clause)).to eq('school DESC, title ASC')
      end
    end

    context 'when sort column is title' do
      let(:sort_column) { 'title' }
      let(:sort_direction) { 'ASC' }

      it 'does not add secondary title sort' do
        expect(presenter.send(:courses_order_clause)).to eq('title ASC')
      end
    end

    context 'when sort params are missing' do
      let(:sort_column) { nil }
      let(:sort_direction) { nil }

      it 'returns default order' do
        expect(presenter.send(:courses_order_clause)).to eq('recent_revision_count DESC, title ASC')
      end
    end
  end

  describe '#filter_title' do
    it 'returns scope unchanged when query is blank' do
      result = presenter.send(:filter_title, courses, nil)
      expect(result.to_sql).to eq(courses.to_sql)
    end

    it 'filters by title (case insensitive)' do
      result = presenter.send(:filter_title, courses, 'test')
      expect(result).to include(course)
    end

    it 'filters by school' do
      result = presenter.send(:filter_title, courses, 'test school')
      expect(result).to include(course)
    end

    it 'filters by term' do
      result = presenter.send(:filter_title, courses, 'test term')
      expect(result).to include(course)
    end

    it 'filters by instructor username' do
      result = presenter.send(:filter_title, courses, 'test_instructor')
      expect(result).to include(course)
    end
  end

  describe '#apply_optional_range_filter' do
    it 'applies both min and max (BETWEEN)' do
      result = presenter.send(:apply_optional_range_filter, courses, 'id', 1, 100)
      expect(result.to_sql).to include('BETWEEN')
    end

    it 'applies only min' do
      result = presenter.send(:apply_optional_range_filter, courses, 'id', 50, nil)
      expect(result.to_sql).to include('>=')
    end

    it 'applies only max' do
      result = presenter.send(:apply_optional_range_filter, courses, 'id', nil, 100)
      expect(result.to_sql).to include('<=')
    end

    it 'returns scope unchanged when both are nil' do
      result = presenter.send(:apply_optional_range_filter, courses, 'id', nil, nil)
      expect(result.to_sql).to eq(courses.to_sql)
    end
  end

  describe '#parse_int' do
    it 'parses valid integers' do
      expect(presenter.send(:parse_int, '42')).to eq(42)
    end

    it 'returns nil for blank values' do
      expect(presenter.send(:parse_int, '')).to be_nil
      expect(presenter.send(:parse_int, nil)).to be_nil
    end

    it 'returns nil for invalid values' do
      expect(presenter.send(:parse_int, 'not_a_number')).to be_nil
    end
  end

  describe '#parse_time' do
    it 'parses valid date strings' do
      result = presenter.send(:parse_time, '2024-01-15', :beginning_of_day)
      expect(result).to be_a(Time)
    end

    it 'returns nil for blank values' do
      expect(presenter.send(:parse_time, '', :beginning_of_day)).to be_nil
      expect(presenter.send(:parse_time, nil, :beginning_of_day)).to be_nil
    end

    it 'returns nil for invalid dates' do
      expect(presenter.send(:parse_time, 'not_a_date', :beginning_of_day)).to be_nil
    end
  end
end
