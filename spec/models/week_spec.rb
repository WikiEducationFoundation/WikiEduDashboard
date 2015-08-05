# == Schema Information
#
# Table name: weeks
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  course_id  :integer
#  created_at :datetime
#  updated_at :datetime
#

require 'rails_helper'

RSpec.describe Week, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
