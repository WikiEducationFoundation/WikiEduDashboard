# frozen_string_literal: true

class AddSalesforceIdsToCourseApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :course_applications, :salesforce_contact_id, :string
    add_column :course_applications, :salesforce_course_contact_id, :string
  end
end
