# == Schema Information
#
# Table name: commons_uploads
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  file_name   :string(255)
#  uploaded_at :datetime
#  usage_count :integer
#  created_at  :datetime
#  updated_at  :datetime
#  thumburl    :string(2000)
#  thumbwidth  :string(255)
#  thumbheight :string(255)
#

FactoryGirl.define do
  factory :commons_upload do
  end
end
