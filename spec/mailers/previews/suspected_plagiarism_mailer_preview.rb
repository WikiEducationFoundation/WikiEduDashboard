# frozen_string_literal: true

class SuspectedPlagiarismMailerPreview < ActionMailer::Preview
  def content_expert_email
    revision = Revision.last
    revision.ithenticate_id = 1234
    SuspectedPlagiarismMailer.content_expert_email(revision, example_user)
  end

  private

  def example_user
    User.new(email: 'sage@example.com', username: 'Ragesoss')
  end
end
