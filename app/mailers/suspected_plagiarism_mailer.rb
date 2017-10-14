# frozen_string_literal: true

class SuspectedPlagiarismMailer < ApplicationMailer
  include ArticleHelper

  def self.alert_content_expert(revision)
    return unless Features.email?
    content_expert = content_expert_for(revision)
    return if content_expert.nil?
    content_expert_email(revision, content_expert).deliver_now
  end

  def content_expert_email(revision, content_expert)
    @revision = revision
    @user = revision.user
    @article = revision.article
    @article_url = @article.url
    @courses_user = @user.courses_users.last
    @course = @courses_user.course
    @talk_page_new_section_url = @courses_user.talk_page_url + '?action=edit&section=new'
    @report_url = 'https://dashboard.wikiedu.org' + @revision.plagiarism_report_link
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
