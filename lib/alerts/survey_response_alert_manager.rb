# frozen_string_literal: true

class SurveyResponseAlertManager
  def initialize
    @answers = recent_answers_to_alert_questions
  end

  def create_alerts
    @answers.each do |answer|
      next unless answer_meets_alert_conditions?(answer)
      next if alert_already_exists?(answer)
      alert = Alert.create(type: 'SurveyResponseAlert',
                           message: alert_message(answer),
                           user_id: answer.user.id,
                           subject_id: answer.question.id,
                           details: details(answer),
                           target_user_id: alert_recipient&.id)
      alert.email_target_user
    end
  end

  def details(answer)
    {
      question: answer.question.question_text,
      answer: answer.answer_text,
      followup: answer.follow_up_answer_text,
      source: source(answer)
    }
  end

  def source(answer)
    question_group = answer.answer_group.question_group
    survey_names = question_group.surveys.map(&:name).join(' .')

    format('Question group: %<qg>s, Survey(s): %<s>s ',
           { qg: question_group.name, s: survey_names })
  end

  private

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def answer_meets_alert_conditions?(answer)
    conditions = answer.question.alert_conditions

    if conditions[:equals]
      return true if answer.answer_text == conditions[:equals]
    elsif conditions[:present]
      return true if answer.answer_text.present?
    elsif conditions[:include]
      return true if answer.answer_text&.include?(conditions[:include])
    end

    false
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

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
