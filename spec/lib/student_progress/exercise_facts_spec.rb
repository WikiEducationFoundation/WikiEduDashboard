# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/student_progress/exercise_facts"

describe StudentProgress::ExerciseFacts do
  let(:course) { create(:course) }
  let(:week) { create(:week, course:, order: 0) }
  let(:student) { create(:user, username: 'Writer') }
  let(:sandbox_exercise) do
    create(:training_module, slug: 'evaluate-exercise', kind: 1,
                             settings: { 'sandbox_location' => 'Evaluate_an_Article' })
  end
  let(:page_exercise) do
    create(:training_module, slug: 'verify-exercise', kind: 1,
                             settings: { 'exercise_path' => 'verify_claim' })
  end

  before do
    create(:block, week:, order: 0, training_module_ids: [sandbox_exercise.id, page_exercise.id])
  end

  def fact(mod)
    described_class.new(StudentProgress::Roster.new(course:, user_ids: [student.id]))
                   .exercise_for(student, mod)
  end

  def complete(mod, completed_at: nil)
    tmu = TrainingModulesUsers.create!(user: student, training_module: mod, completed_at:)
    tmu.mark_completion(true, course.id)
    tmu.save!
  end

  it 'is complete once marked complete for the course, with no time for a sandbox exercise' do
    complete(sandbox_exercise, completed_at: 2.days.ago)
    expect(fact(sandbox_exercise)).to be_completed
    expect(fact(sandbox_exercise).completed_at).to be_nil
  end

  it 'reports the completion time of an exercise done at an in-app page' do
    completed_at = Time.zone.parse('2026-02-01 12:00')
    complete(page_exercise, completed_at:)
    expect(fact(page_exercise).completed_at).to eq(completed_at)
  end

  it 'is in progress once a verification claim is taken, until complete' do
    claim = VerificationClaim.create!(wiki: course.home_wiki, sentence: 'A claim.')
    VerificationClaimAssignment.create!(user: student, course:, verification_claim: claim)
    expect(fact(page_exercise)).to be_in_progress
    expect(fact(sandbox_exercise)).not_to be_in_progress

    complete(page_exercise, completed_at: Time.zone.now)
    expect(fact(page_exercise)).not_to be_in_progress
  end

  it 'links the exercise sandbox, in-app page and instructions' do
    expect(fact(sandbox_exercise).sandbox_url).to end_with('User:Writer/Evaluate_an_Article')
    expect(fact(sandbox_exercise).exercise_url).to be_nil
    expect(fact(page_exercise).exercise_url).to end_with('/verify_claim')
    expect(fact(sandbox_exercise).instructions_url).to include('/training/')
  end

  it 'reports the article an article-title exercise recorded' do
    tmu = TrainingModulesUsers.create!(user: student, training_module: sandbox_exercise)
    tmu.store_exercise_article_title('Ada Lovelace', course.id)
    tmu.save!
    expect(fact(sandbox_exercise).article_title).to eq('Ada Lovelace')
    expect(fact(sandbox_exercise).article_url).to end_with('/wiki/Ada_Lovelace')
  end

  it 'carries the block due date' do
    expect(fact(sandbox_exercise).due_date).to eq(course.blocks.first.calculated_due_date)
  end
end
