# frozen_string_literal: true

require 'csv'

# Every application to one Scholars & Scientists course, one row per applicant,
# with a column for each question answered and each follow-up. Questions follow
# the form's group order, then any groups since removed from the form. Admin-only.
class CourseApplicationsCsvBuilder
  HEADERS = %w[username real_name email status submitted_at decided_at decided_by
               staff_notes].freeze
  # Spreadsheet apps run a cell starting with one of these as a formula, and
  # answers come from anyone with a Wikipedia account.
  FORMULA_START = /\A[=+\-@\t\r]/

  def initialize(course)
    @course = course
    @applications = course.course_applications.includes(:user, :decided_by).order(:created_at)
  end

  def generate_csv
    CSV.generate do |csv|
      csv << HEADERS + columns.map(&:last)
      @applications.each do |application|
        csv << (application_cells(application) + answer_cells(application)).map { |c| safe(c) }
      end
    end
  end

  private

  def application_cells(application)
    user = application.user
    [user.username, user.real_name, user.email, application.status,
     application.created_at, application.decided_at, application.decided_by&.username,
     application.staff_notes]
  end

  def answer_cells(application)
    columns.map do |question, attribute, _header|
      answers[[application.id, question.id]]&.public_send(attribute)
    end
  end

  # [question, answer attribute, header] for each answer column.
  def columns
    @columns ||= questions.flat_map do |question|
      columns = [[question, :answer_text, question.question_text.squish]]
      next columns if question.follow_up_question_text.blank?
      columns << [question, :follow_up_answer_text, question.follow_up_question_text.squish]
    end
  end

  def questions
    group_order = @course.course_application_form&.question_group_ids || []
    answers.values.map(&:question).uniq.sort_by do |question|
      [group_order.index(question.question_group_id) || group_order.size,
       question.question_group_id, question.position.to_i, question.id]
    end
  end

  # Answers keyed by [application id, question id].
  def answers
    @answers ||= Rapidfire::Answer.includes(:question, :answer_group)
                                  .where(answer_group: answer_groups)
                                  .index_by do |answer|
                                    [answer.answer_group.course_application_id, answer.question_id]
                                  end
  end

  def answer_groups
    Rapidfire::AnswerGroup.where(course_application_id: @applications.map(&:id))
  end

  def safe(cell)
    return cell unless cell.is_a?(String) && cell.match?(FORMULA_START)
    "'#{cell}"
  end
end
