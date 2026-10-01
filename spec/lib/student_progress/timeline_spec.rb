# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/student_progress/timeline"

describe StudentProgress::Timeline do
  let(:course) do
    create(:course, start: '2026-01-05', end: '2026-05-01', timeline_start: '2026-01-05')
  end
  let(:week_one) { create(:week, course:, order: 0) }
  let(:week_two) { create(:week, course:, order: 1) }
  let(:training) { create(:training_module, slug: 'tr-a', name: 'Training', kind: 0) }
  let(:later_training) { create(:training_module, slug: 'tr-b', name: 'Later', kind: 0) }
  let(:exercise) { create(:training_module, slug: 'ex-a', name: 'Exercise', kind: 1) }
  let(:discussion) { create(:training_module, slug: 'disc-a', name: 'Discussion', kind: 2) }

  subject(:timeline) do
    described_class.new(StudentProgress::Roster.new(course:, user_ids: []))
  end

  before do
    # Created out of timeline order, so ordering has to come from week and block order.
    create(:block, week: week_two, order: 0, title: 'Peer review an article',
                   training_module_ids: [])
    create(:block, week: week_two, order: 1, title: 'Exercise block',
                   training_module_ids: [exercise.id, training.id])
    create(:block, week: week_one, order: 1, title: 'Trainings',
                   training_module_ids: [later_training.id, training.id, discussion.id])
    create(:block, week: week_one, order: 0, title: 'Empty', training_module_ids: [])
  end

  it 'lists the blocks carrying modules in timeline order' do
    expect(timeline.module_blocks.map(&:title)).to eq(['Trainings', 'Exercise block'])
  end

  it 'separates exercise blocks from training blocks' do
    expect(timeline.exercise_blocks.map(&:title)).to eq(['Exercise block'])
    expect(timeline.training_blocks.map(&:title)).to eq(['Trainings', 'Exercise block'])
  end

  it 'lists training-kind modules once each, in timeline order, without discussions' do
    expect(timeline.training_modules).to eq([later_training, training])
  end

  it 'lists exercise modules' do
    expect(timeline.exercise_modules).to eq([exercise])
  end

  it 'dates a module by the first block it appears in' do
    first_block = timeline.module_blocks.first
    expect(timeline.block_for(training)).to eq(first_block)
    expect(timeline.due_date_for(training)).to eq(first_block.calculated_due_date)
    expect(timeline.due_date_for(create(:training_module, slug: 'elsewhere'))).to be_nil
  end

  describe '#article_stage_for' do
    it 'identifies the article-selection exercises by slug' do
      choose = build(:training_module, slug: 'choose-topic-exercise')
      expect(timeline.article_stage_for(choose)).to eq(:selection)
    end

    it 'identifies exercises done on an assigned-article subpage' do
      settings = { 'assignment_sandbox_location' => 'Bibliography' }
      bibliography = build(:training_module, slug: 'bib', settings:)
      expect(timeline.article_stage_for(bibliography)).to eq(:bibliography)
    end

    it 'is nil for other exercises' do
      expect(timeline.article_stage_for(exercise)).to be_nil
    end
  end

  describe '#article_exercise?' do
    it 'covers the article-stage exercises and continuing to improve the article' do
      settings = { 'assignment_sandbox_location' => 'Outline' }
      expect(timeline.article_exercise?(build(:training_module, slug: 'o', kind: 1, settings:)))
        .to be(true)
      expect(timeline.article_exercise?(build(:training_module, slug: 'choose-topic-exercise',
                                                                kind: 1))).to be(true)
      expect(timeline.article_exercise?(build(:training_module, slug: 'continue-improving-exercise',
                                                                kind: 1))).to be(true)
    end

    it 'leaves out other exercises and training modules' do
      expect(timeline.article_exercise?(exercise)).to be(false)
      expect(timeline.article_exercise?(training)).to be(false)
    end
  end

  describe 'peer review' do
    it 'finds the last block titled for peer review' do
      create(:block, week: week_two, order: 2, title: 'Peer reviews are complete',
                     training_module_ids: [])
      expect(timeline.peer_review_block.title).to eq('Peer reviews are complete')
    end

    it 'does not mistake the response block for the stage' do
      create(:block, week: week_two, order: 3, title: 'Respond to your peer review',
                     training_module_ids: [])
      expect(timeline.peer_review_block.title).to eq('Peer review an article')
    end

    it 'expects reviews only when the course sets a count' do
      expect(timeline.peer_reviews_expected?).to be(false)
      course.update!(flags: { peer_review_count: 2 })
      expect(described_class.new(StudentProgress::Roster.new(course:, user_ids: []))
               .peer_reviews_expected?).to be(true)
    end
  end
end
