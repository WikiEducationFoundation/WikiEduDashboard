# frozen_string_literal: true
# == Schema Information
#
# Table name: course_error_records
#
#  id                  :integer          not null, primary key
#  created_at          :datetime
#  updated_at          :datetime
#  course_id           :integer
#  type_of_error       :string(255)
#  sentry_tag_uuid     :string(255)
#  api_call_url        :text(65535)
#  miscellaneous       :text(65535)
#

class CourseErrorRecord < ApplicationRecord
  belongs_to :course
  serialize :miscellaneous, Hash
end
