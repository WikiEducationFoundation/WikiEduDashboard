# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/mentorship_csv_builder"

# Instructors who checked the "Become a mentor" option in an instructor
# survey, scoped to responses attributable to a course in the given campaign.
# Survey questions are cloned each term with new ids, so the question is
# matched by its answer option wording rather than by id.
class MentorVolunteersCsvBuilder < MentorshipCsvBuilder
  MENTOR_OPTION = /become a mentor/i
  SQL_PREFILTER = '%ecome a mentor%' # cheap LIKE prefilter; MENTOR_OPTION confirms per line

  private

  def rows
    volunteer_pairs.map { |user, course| row(user, course) }
  end

  def volunteer_pairs
    mentor_answers.flat_map do |answer|
      next [] if answer.user.nil?
      campaign_courses_for(answer).map { |course| [answer.user, course] }
    end.uniq
  end

  def mentor_question_ids
    Rapidfire::Question
      .where('answer_options LIKE ?', SQL_PREFILTER)
      .select { |question| mentor_option?(question.answer_options) }
      .map(&:id)
  end

  def mentor_answers
    Rapidfire::Answer
      .where(question_id: mentor_question_ids)
      .where('answer_text LIKE ?', SQL_PREFILTER)
      .includes(:question, answer_group: :user)
      .select { |answer| mentor_option?(answer.answer_text) }
  end

  # Checkbox answers store the selected option labels joined by "\r\n", so a
  # line-level match means the mentor box was actually checked.
  def mentor_option?(text)
    text.to_s.split("\r\n").any? { |line| line.match?(MENTOR_OPTION) }
  end

  def campaign_courses_for(answer)
    courses = notification_courses(answer)
    courses = [fallback_course(answer)].compact if courses.empty?
    courses.uniq.select { |course| course.campaigns.include?(@campaign) }
  end

  # Rapidfire::Answer#course resolves the course via the user's completed
  # SurveyNotifications; the question group may belong to several surveys.
  def notification_courses(answer)
    survey_ids = answer.question.question_group.surveys.pluck(:id)
    survey_ids.filter_map { |survey_id| answer.course(survey_id) }
  end

  # answer_groups.course_id is a guess recorded at submit time; the campaign
  # filter in campaign_courses_for guards against misattribution.
  def fallback_course(answer)
    Course.find_by(id: answer.answer_group.course_id)
  end
end
