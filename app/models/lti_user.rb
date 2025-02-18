# frozen_string_literal: true
# == Schema Information
#
# Table name: lti_users
#
#  id                 :integer          not null, primary key
#  user_id            :integer          not null, foreign_key
#  user_lti_id        :string(255)      not null
#  lms_id             :string(255)      not null
#  lms_family         :string(255)
#

class LtiUser < ApplicationRecord
  belongs_to :user
end
