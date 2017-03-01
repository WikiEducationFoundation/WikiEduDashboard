# frozen_string_literal: true

# == Schema Information
#
# Table name: user_profiles
#
#  id                       :integer          not null, primary key
#  bio                      :string(255)
#  user_id                  :integer

class UserProfile < ActiveRecord::Base
  belongs_to :user
  has_attached_file :image, styles: { thumb: '150x150>' }
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\z/
end
