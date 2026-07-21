# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/system_csv_builder"

describe SystemCsvBuilder do
  before do
    stub_wiki_validation
  end

  let(:en_wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:fr_wiki) { Wiki.get_or_create(language: 'fr', project: 'wikipedia') }

  let(:campaign_a) { create(:campaign, slug: 'spring_2026', title: 'Spring 2026') }
  let(:campaign_b) { create(:campaign, slug: 'fall_2025', title: 'Fall 2025') }

  # Active course: ends in the future
  let!(:active_en_course) do
    create(:course, slug: 'school/active_en_(term)',
                    title: 'Active EN Course',
                    start: 2.months.ago,
                    end: 2.months.from_now,
                    type: 'ClassroomProgramCourse',
                    home_wiki: en_wiki)
  end

  # Archived course: ended well in the past
  let!(:archived_fr_course) do
    create(:course, slug: 'school/archived_fr_(term)',
                    title: 'Archived FR Course',
                    start: 2.years.ago,
                    end: 1.year.ago,
                    type: 'Editathon',
                    home_wiki: fr_wiki)
  end

  # Another active course with a different type
  let!(:active_editathon) do
    create(:course, slug: 'school/active_editathon_(term)',
                    title: 'Active Editathon',
                    start: 1.month.ago,
                    end: 3.months.from_now,
                    type: 'Editathon',
                    home_wiki: en_wiki)
  end

  # Private course: should always be excluded
  let!(:private_course) do
    create(:course, slug: 'school/private_(term)',
                    title: 'Private Course',
                    start: 1.month.ago,
                    end: 2.months.from_now,
                    type: 'ClassroomProgramCourse',
                    home_wiki: en_wiki,
                    private: true)
  end

  before do
    campaign_a.courses << active_en_course
    campaign_a.courses << active_editathon
    campaign_b.courses << archived_fr_course
  end

  describe '#filtered_courses' do
    context 'with no filters' do
      it 'returns all nonprivate courses' do
        builder = described_class.new(filters: {})
        courses = builder.filtered_courses
        expect(courses).to include(active_en_course, archived_fr_course, active_editathon)
        expect(courses).not_to include(private_course)
      end
    end

    context 'with campaign_slug filter' do
      it 'returns only courses in the specified campaign' do
        builder = described_class.new(filters: { campaign_slug: 'spring_2026' })
        courses = builder.filtered_courses
        expect(courses).to include(active_en_course, active_editathon)
        expect(courses).not_to include(archived_fr_course, private_course)
      end
    end

    context 'with date range filter' do
      it 'filters courses by start_date' do
        builder = described_class.new(filters: { start_date: 6.months.ago.to_date.to_s })
        courses = builder.filtered_courses
        expect(courses).to include(active_en_course, active_editathon)
        expect(courses).not_to include(archived_fr_course)
      end

      it 'filters courses by end_date' do
        builder = described_class.new(filters: { end_date: 6.months.from_now.to_date.to_s })
        courses = builder.filtered_courses
        expect(courses).to include(active_en_course, active_editathon)
      end

      it 'filters courses by both start_date and end_date' do
        builder = described_class.new(
          filters: {
            start_date: 3.months.ago.to_date.to_s,
            end_date: 4.months.from_now.to_date.to_s
          }
        )
        courses = builder.filtered_courses
        expect(courses).to include(active_en_course, active_editathon)
        expect(courses).not_to include(archived_fr_course)
      end
    end

    context 'with wiki_domain filter' do
      it 'returns only courses with matching home wiki' do
        builder = described_class.new(filters: { wiki_domain: 'fr.wikipedia.org' })
        courses = builder.filtered_courses
        expect(courses).to include(archived_fr_course)
        expect(courses).not_to include(active_en_course, active_editathon)
      end
    end

    context 'with course_type filter' do
      it 'returns only courses of the specified type' do
        builder = described_class.new(filters: { course_type: 'Editathon' })
        courses = builder.filtered_courses
        expect(courses).to include(archived_fr_course, active_editathon)
        expect(courses).not_to include(active_en_course)
      end
    end

    context 'with status=active filter' do
      it 'returns only currently active courses' do
        builder = described_class.new(filters: { status: 'active' })
        courses = builder.filtered_courses
        expect(courses).to include(active_en_course, active_editathon)
        expect(courses).not_to include(archived_fr_course)
      end
    end

    context 'with status=archived filter' do
      it 'returns only archived courses' do
        builder = described_class.new(filters: { status: 'archived' })
        courses = builder.filtered_courses
        expect(courses).to include(archived_fr_course)
        expect(courses).not_to include(active_en_course, active_editathon)
      end
    end

    context 'with combined filters' do
      it 'applies campaign + course_type filters together' do
        builder = described_class.new(
          filters: { campaign_slug: 'spring_2026', course_type: 'Editathon' }
        )
        courses = builder.filtered_courses
        expect(courses).to include(active_editathon)
        expect(courses).not_to include(active_en_course, archived_fr_course)
      end

      it 'applies wiki_domain + status filters together' do
        builder = described_class.new(
          filters: { wiki_domain: 'en.wikipedia.org', status: 'active' }
        )
        courses = builder.filtered_courses
        expect(courses).to include(active_en_course, active_editathon)
        expect(courses).not_to include(archived_fr_course)
      end
    end

    context 'privacy' do
      it 'always excludes private courses regardless of filters' do
        builder = described_class.new(
          filters: { course_type: 'ClassroomProgramCourse', status: 'active' }
        )
        courses = builder.filtered_courses
        expect(courses).to include(active_en_course)
        expect(courses).not_to include(private_course)
      end
    end
  end

  describe '#generate_csv' do
    it 'generates CSV with filtered courses only' do
      builder = described_class.new(filters: { course_type: 'ClassroomProgramCourse' })
      csv = builder.generate_csv
      expect(csv).to include('Active EN Course')
      expect(csv).not_to include('Archived FR Course')
      expect(csv).not_to include('Active Editathon')
      expect(csv).not_to include('Private Course')
    end

    it 'generates CSV with all nonprivate courses when no filters' do
      csv = described_class.new(filters: {}).generate_csv
      expect(csv).to include('Active EN Course')
      expect(csv).to include('Archived FR Course')
      expect(csv).to include('Active Editathon')
      expect(csv).not_to include('Private Course')
    end

    it 'includes CSV headers' do
      csv = described_class.new(filters: {}).generate_csv
      expect(csv).to include('course_slug')
      expect(csv).to include('title')
      expect(csv).to include('total_edits')
    end

    it 'handles empty search results gracefully without raising errors' do
      builder = described_class.new(filters: { campaign_slug: 'non_existent_campaign' })
      expect { builder.generate_csv }.not_to raise_error
      csv = builder.generate_csv
      expect(csv).to include('course_slug')
      expect(csv).not_to include('Active EN Course')
    end
  end

  describe '#parse_wiki_domain (via wiki_domain filter)' do
    it 'handles multilingual project domains' do
      # wikidata has no language, domain is www.wikidata.org
      wikidata = Wiki.get_or_create(language: nil, project: 'wikidata')
      create(:course, slug: 'school/wikidata_(term)',
                      title: 'Wikidata Course',
                      start: 1.month.ago,
                      end: 2.months.from_now,
                      type: 'BasicCourse',
                      home_wiki: wikidata)
      builder = described_class.new(filters: { wiki_domain: 'www.wikidata.org' })
      courses = builder.filtered_courses
      expect(courses.pluck(:title)).to include('Wikidata Course')
    end
  end
end
