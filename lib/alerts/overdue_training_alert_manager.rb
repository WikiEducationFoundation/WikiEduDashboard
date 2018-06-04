# frozen_string_literal: true

# In contrast to UntrainedStudentsAlertManager, this creates alerts for individual students
# who have overdue trainings, and emails them to remind them to complete the trainings.
class OverdueTrainingAlertManager
  # TODO: Call this as part of the DailyUpdate, for strictly current courses
  def initialize(courses)
    @courses = courses
  end

  def create_alerts
    @courses.each do |course|
      next unless course.type == 'ClassroomProgramCourse'
      course.students.each { |student| manage_alert(course, student) }
    end
  end

  private

  def manage_alert(course, student)
    # TODO: Return instead if last alert was less that 10? days ago.
    return if Alert.exists?(course: course, user: student, type: 'OverdueTrainingAlert')
    status = {}
    overdue = false
    course.training_modules.each do |training_module|
      due_date_manager = TrainingModuleDueDateManager.new(course: course,
                                                          user: student,
                                                          training_module: training_module)
      overdue = true if due_date_manager.overdue?
      status[training_module.slug] = { due_date: due_date_manager.computed_due_date,
                                       status: due_date_manager.deadline_status,
                                       progress: due_date_manager.module_progress }
    end

    return unless overdue
    alert = Alert.create(type: 'OverdueTrainingAlert', user: student,
                         course: course, details: status)
    # OverdueTrainingAlert will not send the email if user has opted out of this email type
    alert.send_email
  end
end
