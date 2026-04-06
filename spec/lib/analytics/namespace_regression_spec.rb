# frozen_string_literal: true

require 'rails_helper'
require_dependency "#{Rails.root}/lib/analytics/course_statistics"

describe CourseStatistics do
  describe 'Namespace 146 (Lexeme) Tracking' do
    let(:course) { create(:course) }
    let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }

    let(:lexeme_article) { create(:article, wiki: wikidata, namespace: 146, title: 'Lexeme:L1') }
    let(:main_article) { create(:article, wiki: wikidata, namespace: 0, title: 'Item:Q1') }

    before do
      allow_any_instance_of(Wiki).to receive(:ensure_wiki_exists)

      
      # Add timeslices mimicking edit activity
      create(:article_course_timeslice, course: course, article: lexeme_article, new_article: true, 
tracked: true, revision_count: 1)
      create(:article_course_timeslice, course: course, article: main_article, new_article: true, 
tracked: true, revision_count: 1)
    end

    it 'accurately counts Lexemes as created articles instead of ignoring them' do
      stats = CourseStatistics.new([course.id])
      report = stats.report_statistics

      # Under the old system (namespace: 0 hardcoded), this would ONLY equal 1.
      # Under the new system, it correctly sees both the Item AND the Lexeme!
      expect(report[:articles_created]).to eq(2)
    end
  end
end
