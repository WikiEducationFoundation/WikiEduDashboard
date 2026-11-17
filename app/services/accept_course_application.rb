# frozen_string_literal: true

# Accepts an application to a Scholars & Scientists course, enrolls the
# applicant as a student, and emails them the course's acceptance email. If any
# step before the email fails, the application is left as it was and `failure`
# holds an i18n key for the reason. A course must be approved before anyone can
# be accepted, which JoinCourse enforces, and its application form must have
# an acceptance email.
#
# Submitted and declined applications can be accepted. Accepting one that is
# already accepted (a double submit, or two staff at once) changes nothing and
# sends nothing.
class AcceptCourseApplication
  attr_reader :failure

  def initialize(application:, staff:)
    @application = application
    @staff = staff
    accept
  end

  def success?
    @failure.nil?
  end

  private

  def accept
    @application.with_lock do
      next if @application.accepted?
      next unless acceptance_email? && enrolled?
      # Inside the lock's transaction, so a failure here also undoes the enrollment.
      @application.update!(status: :accepted, decided_by: @staff, decided_at: Time.zone.now)
      @accepted = true
    end
    # After the transaction commits, so a failed delivery can't undo the decision.
    CourseApplicationMailer.send_acceptance(@application) if @accepted
  end

  def acceptance_email?
    return true if @application.course.course_application_form&.acceptance_email.present?

    @failure = 'course_application_reviews.acceptance_email_missing'
    false
  end

  def enrolled?
    result = JoinCourse.new(course: @application.course, user: @application.user,
                            role: CoursesUsers::Roles::STUDENT_ROLE,
                            skip_application_check: true).result
    # Someone an admin already added to the course is enrolled, which is the
    # point of accepting them.
    return true if result['success'] || result['failure'] == 'cannot_join_twice'

    @failure = JoinCourse.failure_message_key(result['failure'])
    false
  end
end
