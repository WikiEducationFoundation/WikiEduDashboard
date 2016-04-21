class SuspectedPlagiarismMailer < ApplicationMailer
  def self.alert_content_expert(revision)
    return unless Features.email?
    content_expert = revision.user.courses.last.nonstudents.where(greeter: true).last
    return if content_expert.nil?
    context_expert_email(revision, content_expert).deliver_now
  end

  def content_expert_email(revision, content_expert)
    @revision = revision
    @user = revision.user
    @article = revision.article
    @course = @user.courses.last
    mail(to: content_expert.email, subject: "Suspected plagiarism from #{@course.title}")
  end
end
