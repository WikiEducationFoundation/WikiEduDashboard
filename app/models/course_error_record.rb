# frozen_string_literal: true
# == Schema Information
#
# Table name: course_error_records
#
#  id                  :integer          not null, primary key
#  created_at          :datetime
#  updated_at          :datetime
#  type_of_error       :string(255)
#  api_endpoint        :string(255)
#  api_call_query      :string(255)
#

class CourseErrorRecord < ApplicationRecord
end
