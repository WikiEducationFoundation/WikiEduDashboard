require 'rails_helper'
# https://robots.thoughtbot.com/test-rake-tasks-like-a-boss


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
