# frozen_string_literal: true

# Accepts an application to a Scholars & Scientists course and enrolls the
# applicant as a student, together: if enrolling fails, the application is left
# as it was and `failure` holds the JoinCourse reason, a
# `courses.join_failure_details` key. A course must be approved before anyone
# can be accepted, which JoinCourse enforces.
#
# Submitted and declined applications can be accepted. Accepting one that is
# already accepted (a double submit, or two staff at once) changes nothing.
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
      next unless enrolled?
      # Inside the lock's transaction, so a failure here also undoes the enrollment.
      @application.update!(status: :accepted, decided_by: @staff, decided_at: Time.zone.now)
    end
  end

  def enrolled?
    result = JoinCourse.new(course: @application.course, user: @application.user,
                            role: CoursesUsers::Roles::STUDENT_ROLE,
                            skip_application_check: true).result
    # Someone an admin already added to the course is enrolled, which is the
    # point of accepting them.
    return true if result['success'] || result['failure'] == 'cannot_join_twice'

    @failure = result['failure']
    false
  end
end
