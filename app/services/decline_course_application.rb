# frozen_string_literal: true

# Declines a submitted application to a Scholars & Scientists course and emails
# the applicant the decline email. An accepted application can't be declined
# here: the applicant is already in the course, and removing them is done from
# the course itself. The same goes for a submitted application from someone an
# admin has since added to the course as a student. Declining one that is
# already declined sends nothing.
class DeclineCourseApplication
  def initialize(application:, staff:)
    @application = application
    @staff = staff
    decline
  end

  private

  def decline
    @application.with_lock do
      next unless @application.submitted?
      next if @application.user.student?(@application.course)
      @application.update!(status: :declined, decided_by: @staff, decided_at: Time.zone.now)
      @declined = true
    end
    # After the transaction commits, so a failed delivery can't undo the decision.
    CourseApplicationMailer.send_decline(@application) if @declined
  end
end
