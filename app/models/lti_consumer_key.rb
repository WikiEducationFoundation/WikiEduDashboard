# frozen_string_literal: true
# == Schema Information
#
# Table name: lti_consumer_keys
#
#  id                :bigint           not null, primary key
#  key               :string(255)      not null - the OAuth 1.0a consumer key
#  secret            :text(65535)      not null - the shared secret, encrypted
#  course_id         :integer          not null - the course this key connects
#  user_id           :integer          not null - the instructor who issued it
#  lms_instance_guid :string(255)      - pinned at the first launch
#  activated_at      :datetime         - when that first launch happened
#  last_launch_at    :datetime
#  active            :boolean          not null, default TRUE
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

# One LTI 1.1 install's credentials, issued by the Dashboard rather than by
# LTIAAS. An instructor generates a key for their own course from the unlisted
# credentials page and pastes it into Canvas.
#
# Two things make a leaked secret far less useful than LTIAAS's single global
# one. A key is pinned to the Canvas instance that first used it, so it cannot
# be replayed from another Canvas. And a key that is never used stops working
# after UNACTIVATED_LIFETIME, so the claim it carries on a course cannot sit
# around indefinitely waiting to be stolen.
class LtiConsumerKey < ApplicationRecord
  # How long an issued-but-never-launched key stays usable. The instructor
  # pastes it into Canvas within minutes in the ordinary case; a week is
  # generous and still closes the window on a secret that leaked from an inbox.
  UNACTIVATED_LIFETIME = 7.days

  belongs_to :course
  belongs_to :user

  encrypts :secret

  validates :key, :secret, presence: true
  validates :key, uniqueness: true

  before_validation :generate_credentials, on: :create

  scope :active, -> { where(active: true) }

  def self.generate_for(course:, user:)
    transaction do
      # Serializes regenerations for one course. Two simultaneous requests
      # would otherwise both read the same old key, both deactivate it and both
      # insert, leaving two active keys; the second now waits on the course row
      # until the first commits, then sees and replaces the key it made.
      Course.lock.find(course.id)
      # Regenerating replaces: an install can only have one working secret, and
      # leaving the old one usable would defeat the point of regenerating.
      active.where(course:).find_each { |key| key.update!(active: false) }
      create!(course:, user:)
    end
  end

  def activated?
    activated_at.present?
  end

  # An unused key does not live forever. Deliberately not a scope: the launch
  # path wants to tell "expired" apart from "unknown" so it can say so.
  def expired?
    !activated? && created_at < UNACTIVATED_LIFETIME.ago
  end

  # Whether this key may authenticate a launch from the given Canvas instance.
  # An unpinned key accepts its first launch from anywhere, which is what pins
  # it; after that only that Canvas. Never from nowhere: a launch that names no
  # instance would activate the key without pinning it, leaving it usable from
  # anywhere for good.
  def usable_for?(guid)
    return false if guid.blank?
    return false unless active? && !expired?
    return true if lms_instance_guid.nil?

    lms_instance_guid == guid
  end

  # Consume the first launch: pin the Canvas instance and record the moment.
  # Idempotent, so a relaunch just updates the last-launch stamp.
  def record_launch!(guid)
    attributes = { last_launch_at: Time.current }
    attributes.merge!(lms_instance_guid: guid, activated_at: Time.current) unless activated?
    update!(attributes)
  end

  private

  def generate_credentials
    self.key ||= SecureRandom.urlsafe_base64(24)
    self.secret ||= SecureRandom.urlsafe_base64(48)
  end
end
