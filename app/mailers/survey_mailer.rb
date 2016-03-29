class SurveyMailer < ApplicationMailer
  def notification(user)
    @user = user
    mail(to: @user.email, subject: 'A survey is available for your course')
  end
end
