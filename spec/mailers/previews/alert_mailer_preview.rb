# frozen_string_literal: true

require "#{Rails.root}/lib/alerts/survey_response_alert_manager"

#= Preview all emails at http://localhost:3000/rails/mailers/alert_mailer
class AlertMailerPreview < ActionMailer::Preview
  def articles_for_deletion_alert
    AlertMailer.alert(example_alert(type: 'ArticlesForDeletionAlert'), example_user)
  end

  def productive_course_alert
    AlertMailer.alert(example_alert(type: 'ProductiveCourseAlert'), example_user)
  end

  def continued_course_activity_alert
    AlertMailer.alert(example_alert(type: 'ContinuedCourseActivityAlert'), example_user)
  end

  def need_help_alert
    AlertMailer.alert(Alert.where(type: 'NeedHelpAlert').last, example_user)
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
    # Maybe there is no SurveyResponseAlert in the DB
    # To test preview, one must before create an instance
    # To do so: execute the following code in console:
    # AlertMailerPreview.new.send(:create_example_survey_response_alert)
    # Cf. https://github.com/WikiEducationFoundation/WikiEduDashboard/issues/4650
    # Cf. https://github.com/WikiEducationFoundation/WikiEduDashboard/pull/4749
    AlertMailer.alert(SurveyResponseAlert.last, example_user)
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
              course: example_course, id: 9)
  end

  def example_de_userfying_alert
    Alert.new(type: 'DeUserfyingAlert', article: example_article,
              course: Course.last, id: 9, user: example_student,
              details: { logid: 125126035, timestamp: '2021-12-16T08:10:56Z' })
  end

  def example_no_med_training_for_course
    Alert.new(type: 'NoMedTrainingForCourseAlert',
              article: example_article,
              course: example_course)
  end

  def create_example_survey_response_alert
    answer = create_answer
    details =
      {
        question: answer.question.question_text,
        answer: answer.answer_text,
        followup: answer.follow_up_answer_text,
        source: SurveyResponseAlertManager.new.source(answer)
      }

    Alert.create(type: 'SurveyResponseAlert',
                 user: answer.user,
                 subject_id: answer.question.id,
                 details:)
  end

  def create_answer
    survey = Survey.new(name: 'Test survey')
    question_group = Rapidfire::QuestionGroup.new(id: 999999, name: 'Test question group')
    survey.rapidfire_question_groups << question_group
    question_group.surveys << survey
    answer_group = Rapidfire::AnswerGroup
                   .new(id: 999999,
                        question_group:,
                        user: example_student)
    question = Rapidfire::Question
               .create!(id: 999999,
                        question_text: 'What are you studying ?',
                        question_group:)
    answer = Rapidfire::Answer
             .new(answer_text: 'Physics',
                  follow_up_answer_text: 'Really ?',
                  answer_group:,
                  question:)
    answer.user = example_student
    answer
  end
end
