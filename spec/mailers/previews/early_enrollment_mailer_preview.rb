# frozen_string_literal: true
# Preview all emails at http://localhost:3000/rails/mailers/early_enrollment_mailer

class EarlyEnrollmentMailerPreview < ActionMailer::Preview
  def message_to_wiki_experts
    EarlyEnrollmentMailer.email(example_alert)
  end

  private

  def example_alert
    EarlyEnrollmentAlert.new(type: 'EarlyEnrollmentAlert',
                                    course: Course.nonprivate.last || Course.first)
  end
end
