# frozen_string_literal: true

require "#{Rails.root}/lib/alerts/survey_response_alert_manager"

#= Preview all emails at http://localhost:3000/rails/mailers/alert_mailer
class AlertMailerPreview < ActionMailer::Preview
  def articles_for_deletion_alert
    AlertMailer.alert(example_alert(type: 'ArticlesForDeletionAlert'), example_user)
  end

  def blocked_edits_alert
    AlertMailer.alert(example_blocked_edits_alert, example_user)
  end

  def blocked_student_alert
    BlockedUserAlertMailer.email(example_user_blocked_alert)
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
    Alert.new(type: 'DeUserfyingAlert', article: example_article,
              course: Course.nonprivate.last, id: 9, user: example_student,
              details: { logid: 125126035, timestamp: '2021-12-16T08:10:56Z' })
  end

  def example_no_med_training_for_course
    Alert.new(type: 'NoMedTrainingForCourseAlert',
              article: example_article,
              course: example_course)
  end

  def example_survey_response_alert
    question_group = Rapidfire::QuestionGroup.new(name: 'test')
    answer_group = Rapidfire::AnswerGroup.new(question_group:)
    question = Rapidfire::Question.new(id: 1, type: Rapidfire::Questions::Long,
                                       question_group:,
                                       question_text: 'Average speed of an unloaded swallow ?')
    answer = OpenStruct.new(question:, answer_group:)
    question = answer.question
    details =
      {
        question: question.question_text,
        answer: 'This is the answer',
        followup: 'This is the follow-up answer',
        source: SurveyResponseAlertManager.new.source(answer)
      }

    username = example_user.username
    alert = Alert.new(type: 'SurveyResponseAlert',
                      user: example_user,
                      subject_id: question.id,
                      details:)

    alert.tap do |alrt|
      alrt.define_singleton_method(:main_subject) { "What is the speed of an ... - #{username}" }
    end
  end

  def example_blocked_edits_alert
    details = { 'error' =>  { 'code' => 'blocked',
      'info' => 'You have been blocked from editing.',
      'blockinfo' =>
       { 'blockid' => 17605815,
        'blockedby' => 'Blablubbs',
        'blockedbyid' => 22922645,
        'blockreason' => '{{Colocationwebhost}} <!-- Linode -->',
        'blockedtimestamp' => '2023-01-07T12:40:30Z',
        'blockexpiry' => '2025-02-07T12:40:30Z',
        'blocknocreate' => '',
        'blockedtimestampformatted' => '12:40, 7 January 2023',
        'blockexpiryformatted' => '12:40, 7 February 2025',
        'blockexpiryrelative' => 'in 2 years' },
      '*' =>
       'See https://en.wikipedia.org/w/api.php for API usage.' } }
    Alert.new(type: 'BlockedEditsAlert',
              user: example_user,
              details:)
  end

  def example_user_blocked_alert
    user = example_user
    message = "Student #{user.username} have been blocked on Wikipedia.
This mail to inform staff, student as well as instructors."
    alert = Alert.new(type: 'BlockedUserAlert', user:,
                      course: example_course, message:)
    alert.tap do |alrt|
      alrt.define_singleton_method(:main_subject) do
        "User #{user.username} have been blocked on Wikipedia"
      end
    end
  end
end
