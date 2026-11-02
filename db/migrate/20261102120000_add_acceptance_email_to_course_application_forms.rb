# frozen_string_literal: true

# The staff-written message a Scholars & Scientists course's accepted applicants
# are emailed: meeting times, the video call link and passcode, and the like.
class AddAcceptanceEmailToCourseApplicationForms < ActiveRecord::Migration[8.1]
  def change
    add_column :course_application_forms, :acceptance_email, :text
  end
end
