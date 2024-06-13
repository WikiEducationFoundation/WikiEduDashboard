# frozen_string_literal: true

class SuspectedPlagiarismMailerPreview < ActionMailer::Preview
  def content_expert_email
    revision = Revision.last
    user = User.first
    course = Course.nonprivate.last
    article = revision.article
    details = { submission_id: 'ace7aac2-4306-4a7b-86a0-c2b8f9895fd8' }
    alert = PossiblePlagiarismAlert.new(revision:, user:, course:, article:, details:)
    SuspectedPlagiarismMailer.content_expert_email(alert, example_user)
  end

  private

  def example_user
    User.admin
  end
end
