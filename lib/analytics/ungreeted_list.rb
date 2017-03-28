# frozen_string_literal: true

# Provides a CSV of usernames of all students in the user's current courses who
# haven't already been greeted by that user.
class UngreetedList
  def initialize(user)
    currently_supporting = user.supported_courses.strictly_current
    @ungreeted = User.from_courses(currently_supporting).role('student').ungreeted
  end

  def csv
    CSV.generate { |csv| @ungreeted.each { |user| csv << [user.username] } }
  end
end
