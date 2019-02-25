# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wizard_timeline_manager"

describe WizardTimelineManager do
  describe 'researchwrite wizard' do
    let(:course_start) { '2016-08-01' }
    let(:course_end) { '2016-09-23' }
    let(:expected_week_count) { 8 } # based on course start and end
    let(:course) do
      create(:course, start: course_start,
                      end: course_end,
                      timeline_start: course_start,
                      timeline_end: course_end,
                      weekdays: '1111111')
    end
    let(:wizard_id) { 'researchwrite' }
    let(:wizard_params) do
      { 'wizard_output' =>
          { 'output' => ['essentials'],
            'logic' => %w[graded_training
                          critique
                          add_to_article
                          copyedit
                          illustrate
                          explore_to_find_articles
                          medical_topics
                          2_peer_reviewers
                          blog_or_discussion_assignment
                          presentation
                          reflective_essay
                          original_analytical_paper
                          did_you_know
                          good_article_nominations],
            'tags' => [{ key: 'tricky_topic_areas', tag: 'maybe_medical_topics' },
                       { key: 'dyk_and_ga', tag: 'dyk_and_ga' },
                       { key: 'dyk_and_ga', tag: 'dyk_and_ga' }] } }
    end
    let(:subject) do
      described_class.update_timeline_and_tags(course, wizard_id, wizard_params)
    end

    it 'creates weeks and blocks' do
      subject
      expect(course.weeks.count).to eq(expected_week_count)
    end

    it 'assigns correct default values to the blocks' do
      subject
      expect(course.blocks.first.is_deletable).to be(true)
      expect(course.blocks.first.is_editable).to be(true)
    end

    it 'makes the block undeletable if specified' do
      content_path = "#{Rails.root}/config/wizard/#{wizard_id}/content.yml"
      content = YAML.load_file(content_path)
      content['essentials'].first['blocks'].first['is_deletable'] = false
      allow(YAML).to receive(:load_file).and_return(content)

      subject
      expect(course.blocks.first.is_deletable).to be(false)
    end

    it 'makes the block uneditable if specified' do
      content_path = "#{Rails.root}/config/wizard/#{wizard_id}/content.yml"
      content = YAML.load_file(content_path)
      content['essentials'].first['blocks'].first['is_editable'] = false
      allow(YAML).to receive(:load_file).and_return(content)

      subject
      expect(course.blocks.first.is_editable).to be(false)
    end
  end

  describe '#add_tags' do
    it 'updates a tag with the same key as an existing tag' do
      create(:course, id: 10001, timeline_start: Time.zone.today, timeline_end: Time.zone.today)
      create(:tag, id: 1, course_id: 10001, tag: 'use_sandboxes', key: 'draft_and_mainspace')

      wizard_id = 'researchwrite'
      wizard_params = { 'wizard_output' =>
                        { 'tags' =>
                          [{ tag: 'work_live', key: 'draft_and_mainspace' }] } }
      course = Course.find(10001)
      described_class.update_timeline_and_tags(course, wizard_id, wizard_params)
      expect(Tag.find(1).tag).to eq('work_live')
    end
  end
end
