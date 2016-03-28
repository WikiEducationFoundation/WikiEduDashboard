require 'rails_helper'
# https://robots.thoughtbot.com/test-rake-tasks-like-a-boss

describe "surveys:send_notifications" do
  include_context "rake"
  before do
    @user = create(:user)
    @survey1 = create(:survey)
    @cohort1 = create(:cohort, :title => "Test", :slug => 'test')

    # Survey Assignment for Instructors in Courses which end 3 days from today.
    survey_assignment_params = {
      :published => true,
      :courses_user_role => 1,
      :survey_id => @survey1.id, 
      :send_date_days => 3, 
      :send_before => true, 
      :send_date_relative_to => 'end'
    }
    @survey_assignment1 = create(:survey_assignment, survey_assignment_params)

    # Add the Cohort to our survey assignment
    @survey_assignment1.cohorts << @cohort1
    @survey_assignment1.save

    # Un-published Survey Assignment
    @survey_assignment2 = create(:survey_assignment, survey_assignment_params.merge(:published => false))
    @survey_assignment2.cohorts << @cohort1
    @survey_assignment2.save

    # Course with end date that matches Today for the SurveyAssignment
    course_params = {
          start: Time.zone.today - 2.months,
          end: Time.zone.today + 3.days,
          passcode: 'pizza',
          title: 'Underwater basket-weaving'}

    # Add 2 Courses to our Cohort each with an instructor
    2.times do |i|
      course = create(:course, {id: i + 1}.merge(course_params))
      course.courses_users << create(:courses_user,
             course_id: course.id,
             user_id: @user.id,
             role: 1) # instructor
      course.save

      @cohort1.courses << course
    end
    @cohort1.save
  end

  it "knows which users to send survey notifications" do 
    subject.invoke
    expect(SurveyNotification.all.length).to eq(2)
  end

end