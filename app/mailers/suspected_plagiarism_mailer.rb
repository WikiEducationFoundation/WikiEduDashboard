# frozen_string_literal: true

class SuspectedPlagiarismMailer < ApplicationMailer
  include ArticleHelper

  def self.alert_content_expert(alert)
    return unless Features.email?
    content_experts = content_experts_for(alert.user)
    return if content_experts.empty?
    content_expert_email(alert, content_experts).deliver_now
  end

  def content_expert_email(alert, content_experts)
    @diff_url = alert.diff_url
    @user = alert.user
    @article = alert.article
    @article_url = @article.url
    @courses_user = @user.courses_users.last
    @course = alert.course
    @talk_page_new_section_url = @courses_user.talk_page_url + '?action=edit&section=new'
    @report_url = alert.url
    mail(to: @course.instructors.pluck(:email),
         cc: content_experts.pluck(:email),
         reply_to: content_experts.first.email,
         subject: "Possible plagiarism from #{@course.title}")
  end

  def self.content_experts_for(user)
    return [] if user.nil?
    course = user.courses.last
    return [] if course.nil?
    course.nonstudents.where(id: SpecialUsers.wikipedia_experts.pluck(:id))
  end
end
