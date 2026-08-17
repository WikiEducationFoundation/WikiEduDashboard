# frozen_string_literal: true

require 'rails_helper'

describe StudentStatusContext do
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:week) { create(:week, course:, order: 0) }
  let(:exercise_a) do
    create(:training_module, slug: 'ex-a', name: 'Exercise A', kind: 1,
                             settings: { 'sandbox_location' => 'A' })
  end
  let(:exercise_b) do
    create(:training_module, slug: 'ex-b', name: 'Exercise B', kind: 1,
                             settings: { 'sandbox_location' => 'B' })
  end
  let!(:block_a) do
    create(:block, week:, order: 0, title: 'Exercise A', training_module_ids: [exercise_a.id])
  end
  let!(:block_b) do
    create(:block, week:, order: 1, title: 'Exercise B', training_module_ids: [exercise_b.id])
  end

  subject(:context) { described_class.new(course:, user:) }

  before do
    # Block B is due earlier than Block A, so it should win the next step.
    allow_any_instance_of(Block).to receive(:calculated_due_date) do |block|
      block.order.zero? ? Date.new(2026, 3, 1) : Date.new(2026, 2, 1)
    end
  end

  def mark_complete(training_module)
    tmu = TrainingModulesUsers.create!(user:, training_module_id: training_module.id)
    tmu.mark_completion(true, course.id)
    tmu.save
  end

  it 'lists each exercise with its completion state' do
    expect(context.exercise_items.map(&:name)).to contain_exactly('Exercise A', 'Exercise B')
    expect(context.exercises_completed).to eq(0)
  end

  it 'reflects a completed exercise' do
    mark_complete(exercise_a)
    done = context.exercise_items.find { |item| item.name == 'Exercise A' }
    expect(done.done).to be(true)
    expect(context.exercises_completed).to eq(1)
  end

  it 'picks the earliest-due incomplete item as the next step' do
    expect(context.next_step.label).to eq('Exercise B')
  end

  it 'skips a completed item when choosing the next step' do
    mark_complete(exercise_b)
    expect(context.next_step.label).to eq('Exercise A')
  end

  context 'once every training and exercise is done' do
    let(:article) { create(:article, title: 'Ada_Lovelace') }
    let!(:assignment) do
      create(:assignment, course:, user:, article:, article_title: article.title,
                          role: Assignment::Roles::ASSIGNED_ROLE, wiki_id: article.wiki_id)
    end

    before do
      mark_complete(exercise_a)
      mark_complete(exercise_b)
    end

    it 'falls back to the student\'s article as the next step' do
      expect(context.next_step.label).to eq('Ada_Lovelace')
    end

    it 'mirrors the assignment in the articles list' do
      row = context.articles.first
      expect(row.title).to eq('Ada_Lovelace')
      expect(row.role).to eq('editing')
    end
  end
end
