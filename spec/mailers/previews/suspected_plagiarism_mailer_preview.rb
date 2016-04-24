class SuspectedPlagiarismMailerPreview < ActionMailer::Preview
  def content_expert_email
    revision = Revision.last
    revision.ithenticate_id = 1234
    SuspectedPlagiarismMailer.content_expert_email(revision, User.first)
  end
end
