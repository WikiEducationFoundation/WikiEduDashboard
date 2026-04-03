# frozen_string_literal: true

require_relative 'mailer_preview_helpers'

class SuspectedPlagiarismMailerPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  DESCRIPTION = 'Sent when possible plagiarism is detected in a student Wikipedia edit.'
  METHOD_DESCRIPTIONS = {
    content_expert_email: 'Alerts a content expert with article details and a plagiarism report'
  }.freeze

  def content_expert_email
    user = example_user_with_courses_user
    course = example_course
    article = Article.new(title: 'Climate_change_mitigation', wiki: Wiki.default_wiki, namespace: 0)
    details = { submission_id: 'ace7aac2-4306-4a7b-86a0-c2b8f9895fd8',
                wiki_id: Wiki.default_wiki.id }
    alert = PossiblePlagiarismAlert.new(user:, course:, article:, details:)
    SuspectedPlagiarismMailer.content_expert_email(alert, example_content_experts)
  end

  private

  def example_user_with_courses_user
    user = User.new(username: 'Sage (Wiki Ed)', email: 'sage@example.com', permissions: 3)
    talk_url = 'https://en.wikipedia.org/wiki/User_talk:Sage_(Wiki_Ed)'
    stub_cu = OpenStruct.new(talk_page_url: talk_url)
    user.define_singleton_method(:courses_users) { [stub_cu] }
    user
  end

  def example_content_experts
    experts = [User.new(username: 'Ian (Wiki Ed)', real_name: 'Ian (Wiki Ed)',
                        email: 'ian@example.com', permissions: User::Permissions::ADMIN)]
    experts.define_singleton_method(:pluck) { |_col| map(&:email) }
    experts
  end
end
