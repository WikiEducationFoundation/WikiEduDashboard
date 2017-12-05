# frozen_string_literal: true

class SurveyResponseAlertManager
  def initialize
    @answers = recent_answers_to_alert_questions
  end

  def create_alerts
    @answers.each do |answer|
      next unless answer_meets_alert_conditions?(answer)
      next if alert_already_exists?(answer)
      details = {
        question: answer.question.question_text,
        answer: answer.answer_text,
        followup: answer.follow_up_answer_text
      }
      alert = Alert.create(type: 'SurveyResponseAlert',
                           message: alert_message(answer),
                           user_id: answer.user.id,
                           subject_id: answer.question.id,
                           details: details,
                           target_user_id: alert_recipient&.id)
      alert.email_target_user
    end
  end

  private

  def answer_meets_alert_conditions?(answer)
    conditions = answer.question.alert_conditions

    if conditions[:equals]
      return true if answer.answer_text == conditions[:equals]
    elsif conditions[:present]
      return true if answer.answer_text.present?
    end

    false
  end

  RECENT_DAYS = 7
  def recent_answers_to_alert_questions
    Rapidfire::Answer.where(question_id: alert_question_ids)
                     .where('created_at > ?', RECENT_DAYS.day.ago)
  end

  def alert_question_ids
    Rapidfire::Question.where.not(alert_conditions: nil).pluck(:id)
  end

  def alert_already_exists?(answer)
    Alert.exists?(user_id: answer.user.id, subject_id: answer.question.id,
                  type: 'SurveyResponseAlert')
  end

  def alert_message(answer)
    message = String.new("Question: #{answer.question.question_text}")
    message += "\r\n"
    message += "Answer: #{answer.answer_text}"
    message
  end

  def alert_recipient
    SpecialUsers.survey_alerts_recipient
  end
end
