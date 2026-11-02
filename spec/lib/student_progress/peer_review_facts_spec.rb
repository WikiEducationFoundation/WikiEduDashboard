# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/student_progress/peer_review_facts"

describe StudentProgress::PeerReviewFacts do
  let(:course) { create(:course) }
  let(:student) { create(:user, username: 'Reviewer') }
  let(:classmate) { create(:user, username: 'Classmate') }

  def assign(user, title, role: Assignment::Roles::REVIEWING_ROLE)
    Assignment.create!(course:, user:, wiki: course.home_wiki, role:, article_title: title)
  end

  def facts
    described_class.new(StudentProgress::Roster.new(course:, user_ids: [student.id, classmate.id]))
  end

  it 'lists each assigned review with its page and completion' do
    done = assign(student, 'Alpha_article')
    done.update_status(AssignmentPipeline::ReviewStatuses::PEER_REVIEW_COMPLETED)
    assign(student, 'Beta')
    assign(student, 'Own_article', role: Assignment::Roles::ASSIGNED_ROLE)

    reviews = facts.reviews_for(student)
    expect(reviews.reviews.map { |r| [r.article_title, r.completed?] })
      .to eq([['Alpha article', true], ['Beta', false]])
    expect(reviews.reviews.first.assignment_id).to eq(done.id)
    expect(reviews.reviews.first.review_url).to include('Reviewer_Peer_Review')
    expect(reviews.completed_count).to eq(1)
  end

  it 'reports the course\'s expected count, or nil when it sets none' do
    expect(facts.reviews_for(student).expected).to be_nil
    course.update!(flags: { peer_review_count: 2 })
    expect(facts.reviews_for(student).expected).to eq(2)
  end

  it 'knows whether anyone on the roster has a review assigned' do
    expect(facts.any?).to be(false)
    assign(classmate, 'Gamma')
    expect(facts.any?).to be(true)
  end

  it 'is empty for no user' do
    expect(facts.reviews_for(nil).reviews).to eq([])
  end
end
