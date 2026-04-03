# frozen_string_literal: true

class SuspectedPlagiarismMailerPreview < ActionMailer::Preview
  DESCRIPTION = 'Sent when possible plagiarism is detected in a student Wikipedia edit.'
  METHOD_DESCRIPTIONS = {
    content_expert_email: 'Alerts a content expert with article details and a plagiarism report'
  }.freeze

  def content_expert_email
    user = User.new(username: 'Sage (Wiki Ed)', email: 'sage@example.com', permissions: 3)
    course = example_course
    article = Article.new(title: 'Climate_change_mitigation', wiki: Wiki.default_wiki, namespace: 0)
    details = { submission_id: 'ace7aac2-4306-4a7b-86a0-c2b8f9895fd8',
                wiki_id: Wiki.default_wiki.id }
    alert = PossiblePlagiarismAlert.new(user:, course:, article:, details:)
    SuspectedPlagiarismMailer.content_expert_email(alert, example_admin)
  end

  private

  def example_admin
    User.new(username: 'Ian (Wiki Ed)', real_name: 'Ian (Wiki Ed)',
             email: 'ian@example.com', permissions: User::Permissions::ADMIN)
  end

  def example_course
    Course.new(
      title: 'Advanced Topics in Global Health',
      slug: 'Global_Health/Advanced_Topics_(Spring_2025)',
      school: 'University of Maryland',
      expected_students: 24,
      user_count: 22,
      start: 3.months.ago,
      end: 1.month.from_now,
      revision_count: 450
    )
  end
end
