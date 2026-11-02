# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/student_progress/rules"
require_dependency "#{Rails.root}/lib/student_progress/roster"

module StudentProgress
  # Each roster student's peer reviews: the classmates' articles they were
  # assigned to review (`reviewing`-role Assignments), the page each review
  # belongs on, and whether it is done (Rules.review_complete?).
  class PeerReviewFacts
    Review = Struct.new(:assignment_id, :article_title, :article_url, :review_url, :status,
                        :completed, keyword_init: true) do
      def completed?
        completed
      end
    end

    # `expected` is the course's per-student review count, or nil when the
    # course doesn't set one; what to compare progress against then is the
    # consumer's call.
    Reviews = Struct.new(:expected, :reviews, keyword_init: true) do
      def completed_count
        reviews.count(&:completed?)
      end
    end

    # One review's facts, for callers holding a single assignment (the Canvas
    # grade sync's per-student path).
    def self.review_for(assignment)
      Review.new(
        assignment_id: assignment.id,
        # Stored underscored; de-underscored for display like Article#full_title.
        article_title: assignment.article_title.tr('_', ' '),
        article_url: assignment.article_url,
        review_url: "#{assignment.wiki.base_url}/wiki/#{assignment.peer_review_pagename}",
        status: assignment.status,
        completed: Rules.review_complete?(assignment)
      )
    end

    def initialize(roster)
      @roster = roster
      count = roster.course.peer_review_count.to_i
      @expected = count.positive? ? count : nil
    end

    def reviews_for(user)
      reviews = user ? @roster.assignments_for(user.id).select(&:reviewing?) : []
      Reviews.new(expected: @expected, reviews: reviews.map { |a| self.class.review_for(a) })
    end

    # Whether anyone on the roster has a review assigned.
    def any?
      @roster.user_ids.any? { |id| @roster.assignments_for(id).any?(&:reviewing?) }
    end
  end
end
