# frozen_string_literal: true
# == Schema Information
#
# Table name: lti_contexts
#
#  id                 :integer          not null, primary key
#  user_id            :integer          not null, foreign_key
#  user_lti_id        :string(255)      not null - LMS User ID
#  context_id         :string(255)      not null - LMS Context ID (Course ID + Resource Link ID)
#  lms_id             :string(255)      not null - LMS ID
#  lms_family         :string(255) - LMS Family Code (e.g. 'canvas')
#

class LtiContext < ApplicationRecord
  belongs_to :user
end
