require 'rails_helper'

RSpec.describe SurveyAssignment, type: :model do
  before(:each) do
    @survey = create(:survey)
    @cohort = create(:cohort, :title => "Test", :slug => 'test')
    @survey_assignment = create(:survey_assignment, :survey_id => @survey.id)
    @survey_assignment.cohorts << @cohort
  end

  it "has one Survey" do
    expect(@survey_assignment.survey).to be_instance_of(Survey)
  end

  it "has one Cohort" do
    expect(@survey_assignment.cohorts.length).to eq(1)
  end

  describe "#send_at" do
    it "returns a hash for finding courses ready for surveys" do
      @survey_assignment.update({
        send_date_days: 7,
        send_before: true,
        send_date_relative_to: 'end'
      })
      send = @survey_assignment.send_at
      expect(send[:days]).to eq(7)
      expect(send[:before]).to be(true)
      expect(send[:relative_to]).to eq('end')

    end
  end

  describe "Course Model: ready_for_survey scope" do

    it 'returns Courses where `n` days before their course end is Today' do
      course  = create(:course,
          id: 1,
          start: Time.zone.today - 1.month,
          end: Time.zone.today + 1.week,
          passcode: 'pizza',
          title: 'Underwater basket-weaving')

      course.cohorts << @cohort
      course.save

      scope = @survey_assignment.cohorts.first.courses.ready_for_survey({
        :days => 7,
        :before => true,
        :relative_to => 'end'
      })

      expect(scope.length).to eq(1)
    end

    it 'returns Courses where `n` days after their course end is Today' do
      course  = create(:course,
          id: 1,
          start: Time.zone.today - 1.month,
          end: Time.zone.today - 1.week,
          passcode: 'pizza',
          title: 'Underwater basket-weaving')

      course.cohorts << @cohort
      course.save

      scope = @survey_assignment.cohorts.first.courses.ready_for_survey({
        :days => 7,
        :before => false,
        :relative_to => 'end'
      })

      expect(scope.length).to eq(1)
    end

    it 'returns Courses where `n` days `before` their course `start` is Today' do
      course  = create(:course,
          id: 1,
          start: Time.zone.today - 7.days,
          end: Time.zone.today + 1.month,
          passcode: 'pizza',
          title: 'Underwater basket-weaving')

      course.cohorts << @cohort
      course.save

      scope = @survey_assignment.cohorts.first.courses.ready_for_survey({
        :days => 7,
        :before => true,
        :relative_to => 'start'
      })

      expect(scope.length).to eq(1)
    end

    it 'returns Courses where `n` days `before` their course `start` is Today' do
      course  = create(:course,
          id: 1,
          start: Time.zone.today + 7.days,
          end: Time.zone.today + 1.month,
          passcode: 'pizza',
          title: 'Underwater basket-weaving')

      course.cohorts << @cohort
      course.save

      scope = @survey_assignment.cohorts.first.courses.ready_for_survey({
        :days => 7,
        :before => true,
        :relative_to => 'start'
      })

      expect(scope.length).to eq(1)
    end

    it 'returns Courses where `n` days `after` their course `start` is Today' do
      course  = create(:course,
          id: 1,
          start: Time.zone.today - 7.days,
          end: Time.zone.today + 2.month,
          passcode: 'pizza',
          title: 'Underwater basket-weaving')

      course.cohorts << @cohort
      course.save

      scope = @survey_assignment.cohorts.first.courses.ready_for_survey({
        :days => 7,
        :before => false,
        :relative_to => 'start'
      })

      expect(scope.length).to eq(1)
    end
  end

end
