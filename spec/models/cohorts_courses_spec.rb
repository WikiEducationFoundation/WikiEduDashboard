# == Schema Information
#
# Table name: cohorts_courses
#
#  id         :integer          not null, primary key
#  cohort_id  :integer
#  course_id  :integer
#  created_at :datetime
#  updated_at :datetime
#

require 'rails_helper'

RSpec.describe CohortsCourses, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
