# == Schema Information
#
# Table name: requested_accounts
#
#  id         :integer          not null, primary key
#  course_id  :integer
#  username   :string(255)
#  email      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe RequestedAccount, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
