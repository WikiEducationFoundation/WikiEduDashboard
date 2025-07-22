# frozen_string_literal: true

class SuspectedPlagiarismMailerPreview < ActionMailer::Preview
  def content_expert_email
    user = User.first
    course = Course.nonprivate.last
    article = Article.last
    details = { submission_id: 'ace7aac2-4306-4a7b-86a0-c2b8f9895fd8', wiki_id: Wiki.first.id }
    alert = PossiblePlagiarismAlert.new(user:, course:, article:, details:)
    SuspectedPlagiarismMailer.content_expert_email(alert, example_user)
  end

  private

  def example_user
    User.admin
  end
end
