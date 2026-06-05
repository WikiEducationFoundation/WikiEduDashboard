# frozen_string_literal: true

require "#{Rails.root}/lib/alerts/survey_response_alert_manager"

#= Preview all emails at http://localhost:3000/rails/mailers/alert_mailer
class AlertMailerPreview < ActionMailer::Preview # rubocop:disable Metrics/ClassLength
  DESCRIPTION = 'Alert emails sent to staff, instructors, or students for various course events.'
  METHOD_DESCRIPTIONS = {
    articles_for_deletion_alert: "Notifies staff when a student's article is flagged for deletion",
    blocked_edits_alert: 'Notifies staff when a student account is blocked from editing Wikipedia',
    check_timeline_alert: "Prompts staff to review a course's timeline for potential issues",
    productive_course_alert: 'Celebrates a course that has achieved strong Wikipedia contributions',
    continued_course_activity_alert: 'Notes that editing activity continued after a course ended',
    need_help_alert: 'Notifies staff that an instructor or student has requested help',
    over_enrollment_alert: 'Warns staff that a course has more students than expected',
    generic_alert: 'Generic fallback alert email format used for miscellaneous alerts',
    de_userfying_alert: 'Notifies staff when a student sandbox is moved to mainspace',
    no_med_training_for_course_alert: 'Warns of a medical topics course without required training',
    survey_response_alert: 'Notifies staff of a notable response submitted through a survey'
  }.freeze
  METHOD_RECIPIENTS = {
    articles_for_deletion_alert: 'staff',
    blocked_edits_alert: 'staff',
    check_timeline_alert: 'staff',
    continued_course_activity_alert: 'staff',
    de_userfying_alert: 'staff',
    generic_alert: 'staff',
    need_help_alert: 'staff',
    no_med_training_for_course_alert: 'staff',
    over_enrollment_alert: 'staff',
    productive_course_alert: 'staff',
    survey_response_alert: 'staff'
  }.freeze

  def articles_for_deletion_alert
    AlertMailer.alert(example_alert(type: 'ArticlesForDeletionAlert'), example_user)
  end

  def blocked_edits_alert
    AlertMailer.alert(example_blocked_edits_alert, example_user)
  end

  def check_timeline_alert
    AlertMailer.alert(example_alert(type: 'CheckTimelineAlert'), example_user)
  end

  def productive_course_alert
    AlertMailer.alert(example_alert(type: 'ProductiveCourseAlert'), example_user)
  end

  def continued_course_activity_alert
    AlertMailer.alert(example_alert(type: 'ContinuedCourseActivityAlert'), example_user)
  end

  def need_help_alert
    AlertMailer.alert(example_alert(type: 'NeedHelpAlert'), example_user)
  end

  def over_enrollment_alert
    AlertMailer.alert(example_over_enrollment_alert, example_user)
  end

  def generic_alert
    AlertMailer.alert(example_alert, example_user)
  end

  def de_userfying_alert
    AlertMailer.alert(example_de_userfying_alert, example_user)
  end

  def no_med_training_for_course_alert
    AlertMailer.alert(example_no_med_training_for_course, example_user)
  end

  def survey_response_alert
    AlertMailer.alert(example_survey_response_alert, example_user)
  end

  private

  def example_user
    User.new(email: 'sage@example.com', username: 'Ragesoss', permissions: 1)
  end

  def example_student
    User.new(email: 'nospam@nospam.com', username: 'Me_student', permissions: 0)
  end

  def example_course
    Course.new(title: "Apostrophe's Folly", slug: "School/Apostrophe's_Folly_(Spring_2019)",
               expected_students: 5, user_count: 11)
  end

  def example_article
    Article.new(title: "King's_Gambit", wiki: Wiki.first, namespace: 0)
  end

  def example_over_enrollment_alert
    Alert.new(type: 'OverEnrollmentAlert', course: example_course, id: 9)
  end

  def example_alert(type: 'HighQualityArticleEditAlert')
    Alert.new(type:, article: example_article,
              course: example_course, id: 9,
              user: User.new(username: 'Alice Student'))
  end

  def example_de_userfying_alert
    course = example_course.tap { |c| c.define_singleton_method(:home_wiki) { Wiki.default_wiki } }
    Alert.new(type: 'DeUserfyingAlert', article: example_article,
              course:, id: 9, user: example_student,
              details: { logid: 125126035,
                         timestamp: '2021-12-16T08:10:56Z',
                         title: 'User:Ragesoss/sandbox',
                         ai_edit_alert_ids: [54, 78] })
  end

  def example_no_med_training_for_course
    Alert.new(type: 'NoMedTrainingForCourseAlert',
              article: example_article,
              course: example_course)
  end

  def example_survey_response_alert
    question_group = Rapidfire::QuestionGroup.new(name: 'test')
    answer_group = Rapidfire::AnswerGroup.new(question_group:)
    question = survey_example_question(question_group)
    answer = OpenStruct.new(question:, answer_group:)
    username = example_user.username
    alert = Alert.new(type: 'SurveyResponseAlert', user: example_user,
                      subject_id: question.id, details: survey_alert_details(answer))
    alert.tap do |alrt|
      alrt.define_singleton_method(:main_subject) { "What is the speed of an ... - #{username}" }
    end
  end

  def survey_example_question(question_group)
    Rapidfire::Question.new(id: 1, type: Rapidfire::Questions::Long,
                            question_group:,
                            question_text: 'Average speed of an unloaded swallow?')
  end

  def survey_alert_details(answer)
    { question: answer.question.question_text,
      answer: 'This is the answer',
      followup: 'This is the follow-up answer',
      source: SurveyResponseAlertManager.new.source(answer) }
  end

  def example_blocked_edits_alert
    details = { 'error' => { 'code' => 'blocked',
                              'info' => 'You have been blocked from editing.',
                              'blockinfo' => example_blockinfo,
                              '*' => 'See https://en.wikipedia.org/w/api.php for API usage.' } }
    Alert.new(type: 'BlockedEditsAlert', user: example_user, details:)
  end

  def example_blockinfo
    { 'blockid' => 17605815,
      'blockedby' => 'Blablubbs',
      'blockedbyid' => 22922645,
      'blockreason' => '{{Colocationwebhost}} <!-- Linode -->',
      'blockedtimestamp' => '2023-01-07T12:40:30Z',
      'blockexpiry' => '2025-02-07T12:40:30Z',
      'blockedtimestampformatted' => '12:40, 7 January 2023',
      'blockexpiryformatted' => '12:40, 7 February 2025',
      'blockexpiryrelative' => 'in 2 years' }
  end

end
