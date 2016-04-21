class SuspectedPlagiarismMailer < ApplicationMailer
  def self.alert_content_expert(revision)
    return unless Features.email?
    content_expert = content_expert_for(revision)
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

  def self.content_expert_for(revision)
    user = revision.user
    return if user.nil?
    course = user.courses.last
    return if course.nil?
    course.nonstudents.where(greeter: true).last
  end
end
