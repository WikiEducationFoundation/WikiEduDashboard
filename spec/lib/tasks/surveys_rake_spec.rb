require 'rails_helper'
# https://robots.thoughtbot.com/test-rake-tasks-like-a-boss


describe "surveys:create_notifications" do
  include_context "rake"
  include_context "survey_assignment"

  it "creates SurveyNotifications for each courses_user ready for a survey" do
    subject.invoke
    expect(SurveyNotification.all.length).to eq(2)
  end

  it "only creates notifications with unique courses_user id and survey id combinations" do
    subject.invoke
    total_notifications = SurveyNotification.all.count
    new_survey = create(:survey)
    course = create(:course, @course_params.merge(title: "Tuba Playing"))
    course.courses_users << create(:courses_user,
           course_id: course.id,
           user_id: @user.id,
           role: 1) # instructor
    course.save
    @cohort1.courses << course
    @cohort1.save
    subject.invoke
    survey_assignment = create(:survey_assignment, @survey_assignment_params.merge(survey_id: new_survey.id))
    survey_assignment.cohorts << @cohort1
    survey_assignment.save
    expect(SurveyNotification.all.count).to eq(total_notifications + 1)
  end
end

describe "surveys:send_notifications" do
  include_context "rake"
  include_context "survey_assignment"
  before do
    rake['surveys:create_notifications'].invoke
    subject.invoke
  end

  it "sends emails for all SurveyNotifications with emails that haven\'t been sent" do
    expect(ActionMailer::Base.deliveries.count).to eq(2)
  end

  it "sends emails to the users email address" do
    expect(ActionMailer::Base.deliveries.first.to.include?(@user.email)).to be(true)
    expect(ActionMailer::Base.deliveries.last.to.include?(@user.email)).to be(true)
  end

  it "sets SurveyNotification email_sent boolean attribute to true after sending" do
    expect(SurveyNotification.where(:email_sent => false).length).to eq(0)
  end

  it "only sends emails for notifications which haven't been dismissed" do
    subject.invoke
    expect(ActionMailer::Base.deliveries.count).to eq(2)
  end
end
