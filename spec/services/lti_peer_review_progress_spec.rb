# frozen_string_literal: true

require 'rails_helper'

describe LtiPeerReviewProgress do
  let(:course) { create(:course) }
  let(:student) { create(:user, username: 'reviewer') }

  def expect_reviews(count)
    course.flags[:peer_review_count] = count
    course.save!
  end

  def assign_review(title, completed: false)
    assignment = Assignment.create!(course:, user: student, wiki: course.home_wiki,
                                    role: Assignment::Roles::REVIEWING_ROLE,
                                    article_title: title)
    if completed
      assignment.update_sandbox_status(
        :review, AssignmentPipeline::SandboxStatuses::EXISTS_IN_USERSPACE
      )
    end
    assignment
  end

  it 'scores the fraction of expected reviews the student has written' do
    expect_reviews(2)
    assign_review('First', completed: true)
    assign_review('Second')

    progress = described_class.new(course, student)
    expect(progress.score_given).to eq(0.5)
    expect(progress.score_maximum).to eq(1.0)
  end

  it 'is complete once every expected review is written' do
    expect_reviews(2)
    assign_review('First', completed: true)
    assign_review('Second', completed: true)

    expect(described_class.new(course, student).score_given).to eq(1.0)
  end

  # Taking a review is not doing it: the assignment exists as soon as the
  # instructor (or the random assigner) hands it out.
  it 'does not count a review whose page has not been written' do
    expect_reviews(1)
    assign_review('First')

    expect(described_class.new(course, student).score_given).to eq(0.0)
  end

  it 'counts a review page that was moved rather than left in userspace' do
    expect_reviews(1)
    review = assign_review('First')
    review.update_sandbox_status(:review,
                                 AssignmentPipeline::SandboxStatuses::EXISTS_IN_MAINSPACE)

    expect(described_class.new(course, student).score_given).to eq(1.0)
  end

  # A student who reviewed more than was asked of them is finished, not over 100%.
  it 'caps the score at the maximum' do
    expect_reviews(1)
    assign_review('First', completed: true)
    assign_review('Second', completed: true)

    expect(described_class.new(course, student).score_given).to eq(1.0)
  end

  it 'falls back to one expected review when the course has no setting' do
    assign_review('First', completed: true)
    expect(described_class.new(course, student).total_count).to eq(1)
    expect(described_class.new(course, student).score_given).to eq(1.0)
  end

  # The setting can be turned off after the column was imported; there is then
  # nothing to report rather than a zero.
  it 'is not gradable for a course expecting no reviews' do
    expect_reviews(0)
    expect(described_class.new(course, student)).not_to be_gradable
  end

  it 'reports the counts and comment the drill-down and gradebook share' do
    expect_reviews(3)
    assign_review('First', completed: true)

    progress = described_class.new(course, student)
    expect(progress.completed_count).to eq(1)
    expect(progress.total_count).to eq(3)
    expect(progress.comment).to eq('1 of 3 peer reviews completed')
  end

  it 'exposes each review with its completion state, for the drill-down' do
    expect_reviews(2)
    assign_review('Done one', completed: true)
    assign_review('Not yet')

    statuses = described_class.new(course, student).review_statuses
    expect(statuses.map { |assignment, _done| assignment.article_title })
      .to contain_exactly('Done_one', 'Not_yet')
    expect(statuses.select { |_a, done| done }.length).to eq(1)
  end

  # Editing assignments are the student's own article, reported by other columns.
  it 'ignores the student’s own editing assignment' do
    expect_reviews(1)
    Assignment.create!(course:, user: student, wiki: course.home_wiki,
                       role: Assignment::Roles::ASSIGNED_ROLE, article_title: 'Mine')

    expect(described_class.new(course, student).completed_count).to eq(0)
  end

  it 'changes its signature when a review is written' do
    expect_reviews(2)
    assign_review('First', completed: true)
    before = described_class.new(course, student).signature
    assign_review('Second', completed: true)

    expect(described_class.new(course, student).signature).not_to eq(before)
  end
end
