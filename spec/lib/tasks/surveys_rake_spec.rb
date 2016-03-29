require 'rails_helper'
# https://robots.thoughtbot.com/test-rake-tasks-like-a-boss


describe "surveys:create_notifications" do
  include_context "rake"
  include_context "survey_assignment"

  it "creates SurveyNotifications for each courses_user ready for a survey" do 
    subject.invoke
    expect(SurveyNotification.all.length).to eq(2)
  end
end

describe "surveys:send_notifications" do
  include_context "rake"
  include_context "survey_assignment"
  before do
    rake['surveys:create_notifications'].invoke
  end

  it "creates Dashboard Notifications for all SurveyNotifications that haven\'t been created" do 
    
  end

  it "sends emails for all SurveyNotifications with emails that haven\'t been sent" do 
    
  end
end