class SuspectedPlagiarismMailerPreview < ActionMailer::Preview
  def content_expert_email
    revision = Revision.last
    revision.report_url = 'https://crookedtimber.org'
    SuspectedPlagiarismMailer.content_expert_email(revision, User.first)
  end
end
