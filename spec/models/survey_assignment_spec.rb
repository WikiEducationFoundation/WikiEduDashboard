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
    let(:course_start) { Time.zone.today - 1.month }
    let(:course_end) { Time.zone.today + 1.month }

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

  describe "#total_notifications" do
    let(:course_start) { Time.zone.today - 1.month }
    let(:course_end) { Time.zone.today + 1.month }

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

    it 'returns an empty array if no notifications match the provided courses_user and survey ids' do
      notification = create(:survey_notification, courses_users_id: 1)
      @survey_assignment.survey_notifications << notification
      @survey_assignment.save
      expect(SurveyAssignment.by_courses_user_and_survey(
        courses_users_id: 99,
        survey_id: @survey.id
      ).length).to eq(0)
    end
  end

  describe 'Course Model: ready_for_survey scope' do
    let(:n) { 7 }
    let(:course_scope) do
      @survey_assignment.cohorts.first.courses.ready_for_survey(
        days: n,
        before: before,
        relative_to: relative_to)
    end
    let(:course_start) { Time.zone.today - 1.month }
    let(:course_end) { Time.zone.today + 1.month }

    context 'when `n` days before their course end is Today' do
      let(:course_end) { Time.zone.today - n.days }
      let(:before) { true }
      let(:relative_to) { 'end' }

      it 'returns the Course' do
        course.cohorts << @cohort
        course.save
        expect(course_scope.length).to eq(1)
      end
    end

    context 'when `n` days after their course end is Today' do
      let(:course_end) { Time.zone.today - n.days }
      let(:before) { false }
      let(:relative_to) { 'end' }

      it 'returns the Course ' do
        course.cohorts << @cohort
        course.save
        expect(course_scope.length).to eq(1)
      end
    end

    context 'when `n` days `before` their course `start` is Today' do
      let(:course_start) { Time.zone.today + n.days }
      let(:before) { true }
      let(:relative_to) { 'start' }

      it 'returns the Course' do
        course.cohorts << @cohort
        course.save
        expect(course_scope.length).to eq(1)
      end
    end

    context 'when `n` days `after` their course `start` is Today' do
      let(:course_start) { Time.zone.today - n.days }
      let(:before) { false }
      let(:relative_to) { 'start' }

      it 'returns the Course' do
        course.cohorts << @cohort
        course.save
        expect(course_scope.length).to eq(1)
      end
    end

    context 'when `n` days `after` their course `start` is tomorrow' do
      let(:course_start) { Time.zone.tomorrow - n.days }
      let(:before) { false }
      let(:relative_to) { 'start' }

      it 'does not return the Course' do
        course.cohorts << @cohort
        course.save
        expect(course_scope.length).to eq(0)
      end
    end
  end

  describe "Course Model: will_be_ready_for_survey scope" do
    it 'returns Courses where `n` days before their course end is after Today' do
      course  = create(:course,
          id: 1,
          start: Time.zone.today - 7.days,
          end: Time.zone.today + 1.month,
          passcode: 'pizza',
          title: 'Underwater basket-weaving')

      course.cohorts << @cohort
      course.save

      scope = @survey_assignment.cohorts.first.courses.will_be_ready_for_survey({
        :days => 7,
        :before => true,
        :relative_to => 'end'
      })

      expect(scope.length).to eq(1)
    end
    it 'returns Courses where `n` days after their course end is after Today' do
      course  = create(:course,
          id: 1,
          start: Time.zone.today - 7.days,
          end: Time.zone.today + 1.month,
          passcode: 'pizza',
          title: 'Underwater basket-weaving')

      course.cohorts << @cohort
      course.save

      scope = @survey_assignment.cohorts.first.courses.will_be_ready_for_survey({
        :days => 7,
        :before => false,
        :relative_to => 'end'
      })

      expect(scope.length).to eq(1)
    end
    it 'returns Courses where `n` days before their course start is after Today' do
      course  = create(:course,
          id: 1,
          start: Time.zone.today + 2.weeks,
          end: Time.zone.today + 1.month,
          passcode: 'pizza',
          title: 'Underwater basket-weaving')

      course.cohorts << @cohort
      course.save

      scope = @survey_assignment.cohorts.first.courses.will_be_ready_for_survey({
        :days => 7,
        :before => true,
        :relative_to => 'start'
      })

      expect(scope.length).to eq(1)
    end
    it 'returns Courses where `n` days after their course start is after Today' do
      course  = create(:course,
          id: 1,
          start: Time.zone.today + 2.weeks,
          end: Time.zone.today + 1.month,
          passcode: 'pizza',
          title: 'Underwater basket-weaving')

      course.cohorts << @cohort
      course.save

      scope = @survey_assignment.cohorts.first.courses.will_be_ready_for_survey({
        :days => 7,
        :before => false,
        :relative_to => 'start'
      })

      expect(scope.length).to eq(1)
    end
  end
end
