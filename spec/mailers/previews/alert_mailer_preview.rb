# Preview all emails at http://localhost:3000/rails/mailers/survey_mailer
class AlertPreview < ActionMailer::Preview
  def alert
    AlertMailer.alert(Alert.last, User.last)
  end
end
