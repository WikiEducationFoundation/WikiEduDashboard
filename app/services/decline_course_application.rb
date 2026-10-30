# frozen_string_literal: true

# Declines a submitted application to a Scholars & Scientists course. An
# accepted application can't be declined here: the applicant is already in the
# course, and removing them is done from the course itself.
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
      @application.update!(status: :declined, decided_by: @staff, decided_at: Time.zone.now)
    end
  end
end
