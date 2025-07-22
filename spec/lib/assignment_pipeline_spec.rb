# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/assignment_pipeline"

describe AssignmentPipeline do
  describe 'Assignments' do
    let(:course) { create(:course) }
    let(:user) { create(:user) }
    let(:courses_user) do
      create(:courses_user, user_id: user.id, course_id: course.id, role: 0)
    end

    let(:assignment) do
      create(:assignment, course_id: course.id,
                          user_id: user.id,
                          role: 0,
                          article_id: nil,
                          article_title: 'Deep_Sea_Fishing')
    end

    describe '#status' do
      it 'returns the "not_yet_started" status if there is no status' do
        pipeline = described_class.new(assignment:)

        actual = pipeline.status
        expected = described_class::AssignmentStatuses::NOT_YET_STARTED
        expect(actual).to equal(expected)
      end
    end

    describe '#all_statuses' do
      it 'returns all the available statuses for the provided pipeline' do
        pipeline = described_class.new(assignment:)

        actual = pipeline.all_statuses
        expect(actual.length).to equal(5)
      end
    end

    describe '#update_status' do
      it 'sets the assignment status and updates the time' do
        pipeline = described_class.new(assignment:)

        status = described_class::AssignmentStatuses::READY_FOR_MAINSPACE
        pipeline.update_status(status)
        current_status = pipeline.status
        expect(current_status).to eq(status)

        updated_at = assignment.flags[:assignment][:updated_at]
        expect(updated_at).to be_within(30.seconds).of(Time.zone.now)
      end

      it 'will only set the assignment if the status is valid' do
        pipeline = described_class.new(assignment:)
        in_progress_status = described_class::AssignmentStatuses::NOT_YET_STARTED
        expect(pipeline.status).to eq(in_progress_status)
        expect(assignment.flags[:assignment]).to be(nil)

        status = 'unknown_status'
        pipeline.update_status(status)
        expect(pipeline.status).to eq(in_progress_status)
        expect(assignment.flags[:assignment]).to be(nil)
      end
    end
  end

  describe 'Reviews' do
    let(:course) { create(:course) }
    let(:user) { create(:user) }
    let(:courses_user) do
      create(:courses_user, user_id: user.id, course_id: course.id, role: 0)
    end

    let(:assignment) do
      create(:assignment, course_id: course.id,
                          user_id: user.id,
                          role: 1,
                          article_id: nil,
                          article_title: 'Deep_Sea_Fishing')
    end

    describe '#status' do
      it 'returns the "reading_article" status if there is no status' do
        pipeline = described_class.new(assignment:)

        actual = pipeline.status
        expected = described_class::ReviewStatuses::READING_ARTICLE
        expect(actual).to equal(expected)
      end
    end

    describe '#all_statuses' do
      it 'returns all the available statuses for the provided pipeline' do
        pipeline = described_class.new(assignment:)

        actual = pipeline.all_statuses
        expect(actual.length).to equal(4)
      end
    end

    describe '#update_status' do
      it 'sets the assignment status and updates the time' do
        pipeline = described_class.new(assignment:)

        status = described_class::ReviewStatuses::PEER_REVIEW_COMPLETED
        pipeline.update_status(status)
        current_status = pipeline.status
        expect(current_status).to eq(status)

        updated_at = assignment.flags[:review][:updated_at]
        expect(updated_at).to be_within(30.seconds).of(Time.zone.now)
      end

      it 'will only set the assignment if the status is valid' do
        pipeline = described_class.new(assignment:)
        in_progress_status = described_class::ReviewStatuses::READING_ARTICLE
        expect(pipeline.status).to eq(in_progress_status)
        expect(assignment.flags[:review]).to be(nil)

        status = 'unknown_status'
        pipeline.update_status(status)
        expect(pipeline.status).to eq(in_progress_status)
        expect(assignment.flags[:review]).to be(nil)
      end
    end
  end
end
