# frozen_string_literal: true
# Preview all emails at http://localhost:3000/rails/mailers/wiki_expert_notification

class WikiExpertNotificationPreview < ActionMailer::Preview
  def message_to_wiki_experts
    WikiExpertNotificationMailer.email(example_alert)
  end

  private

  def example_alert
    WikiExpertNotificationAlert.new(type: 'WikiExpertNotificationAlert',
                                    course: Course.nonprivate.last || Course.first)
  end
end
