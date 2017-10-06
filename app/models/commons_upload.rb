# frozen_string_literal: true

# == Schema Information
#
# Table name: commons_uploads
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  file_name   :string(2000)
#  uploaded_at :datetime
#  usage_count :integer
#  created_at  :datetime
#  updated_at  :datetime
#  thumburl    :string(2000)
#  thumbwidth  :string(255)
#  thumbheight :string(255)
#  deleted     :boolean          default(FALSE)
#

#= Upload model
class CommonsUpload < ActiveRecord::Base
  belongs_to :user

  ####################
  # Instance methods #
  ####################
  def url
    "https://commons.wikimedia.org/wiki/#{file_name}"
  end
end
