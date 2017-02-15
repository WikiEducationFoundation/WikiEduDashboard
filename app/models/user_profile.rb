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
end
