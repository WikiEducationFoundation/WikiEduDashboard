# frozen_string_literal: true

# == Schema Information
#
# Table name: user_profiles
#
#  id                 :integer          not null, primary key
#  bio                :text(65535)
#  user_id            :integer
#  image_file_name    :string(255)
#  image_content_type :string(255)
#  image_file_size    :integer
#  image_updated_at   :datetime
#  location           :string(255)
#  institution        :string(255)
#

class UserProfile < ActiveRecord::Base
  belongs_to :user
  has_attached_file :image, styles: { thumb: '150x150>' }
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\z/
end
