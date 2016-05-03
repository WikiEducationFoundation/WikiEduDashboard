require 'rails_helper'
require 'spec_helper'

RSpec.describe SurveyAssignment, type: :model do
  before(:each) do
    @survey = create(:survey)
    @cohort = create(:cohort, title: 'Test', slug: 'test')
    @survey_assignment = create(:survey_assignment, survey_id: @survey.id, published: true)
    @survey_assignment.cohorts << @cohort
  end

  let(:course) { create(:course, start: course_start, end: course_end) }
  let(:course_start) { Time.zone.today - 1.month }
  let(:course_end) { Time.zone.today + 1.month }

  it 'has one Survey' do
    expect(@survey_assignment.survey).to be_instance_of(Survey)
  end

  it 'has one Cohort' do
    expect(@survey_assignment.cohorts.length).to eq(1)
  end

  describe '#send_at' do
    it 'returns a hash for finding courses ready for surveys' do
      @survey_assignment.update(
        send_date_days: 7,
        send_before: true,
        send_date_relative_to: 'end'
      )
      send = @survey_assignment.send_at
      expect(send[:days]).to eq(7)
      expect(send[:before]).to be(true)
      expect(send[:relative_to]).to eq('end')
    end
  end

  describe '#active?' do
    it 'returns true if there are yet-to-be-notified courses' do
      course.cohorts << @cohort
      course.save
      @survey_assignment.update(
        send_date_days: 7,
        send_before: true,
        send_date_relative_to: 'end'
      )

      expect(@survey_assignment.active?).to be(true)
    end
  end

  describe '#status' do
    let(:survey_assignment) do
      create(:survey_assignment, survey_id: survey.id, published: published, courses_user_role: 1)
    end
    let(:survey) { create(:survey, closed: closed) }
    let(:closed) { false }
    let(:subject) { survey_assignment.status }

    context 'when it is not published' do
      let(:published) { false }
      it 'returns `Draft`' do
        expect(subject).to eq('Draft')
      end
    end

    context 'when it is published but has no applicable users' do
      let(:published) { true }
      it 'returns `Pending`' do
        expect(subject).to eq('Pending')
      end
    end

    context 'when it is published and has applicable users' do
      let(:published) { true }

      it 'returns `Active`' do
        course.cohorts << @cohort
        survey_assignment.cohorts << @cohort
        create(:user, id: 1)
        create(:courses_user, user_id: 1, course_id: course.id, role: 1)
        expect(subject).to eq('Active')
      end
    end

    context 'when it is published and has applicable users and is closed' do
      let(:published) { true }
      let(:closed) { true }

      it 'returns `Closed`' do
        course.cohorts << @cohort
        survey_assignment.cohorts << @cohort
        create(:user, id: 1)
        create(:courses_user, user_id: 1, course_id: course.id, role: 1)
        expect(subject).to eq('Closed')
      end
    end
  end

  describe '#total_notifications' do
    it 'returns the total number of users who will receive a notification' do
      course.cohorts << @cohort
      course.save

      create(:user, id: 1)
      create(:courses_user,
             user_id: 1,
             course_id: course.id,
             role: 1)

      @survey_assignment.update(
        courses_user_role: 1,
        send_date_days: 7,
        send_before: true,
        send_date_relative_to: 'end'
      )

      expect(@survey_assignment.total_notifications).to eq(1)
    end
  end

  describe '#by_courses_user_and_survey Scope' do
    it 'returns notifications that match the provided courses_user and survey ids' do
      notification = create(:survey_notification, courses_users_id: 1)
      @survey_assignment.survey_notifications << notification
      @survey_assignment.save
      expect(SurveyAssignment.by_courses_user_and_survey(
        courses_users_id: 1,
        survey_id: @survey.id
      ).length).to eq(1)
    end

    it 'returns an empty array if no notifications match the courses_user and survey ids' do
      notification = create(:survey_notification, courses_users_id: 1)
      @survey_assignment.survey_notifications << notification
      @survey_assignment.save
      expect(SurveyAssignment.by_courses_user_and_survey(
        courses_users_id: 99,
        survey_id: @survey.id
      ).length).to eq(0)
    end
  end
end
