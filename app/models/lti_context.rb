# frozen_string_literal: true
# == Schema Information
#
# Table name: lti_contexts
#
#  id                    :integer          not null, primary key
#  user_id               :integer          - nullable; nil for NRPS-discovered
#                                            members who haven't completed
#                                            Wikipedia OAuth yet
#  user_lti_id           :string(255)      not null - LMS User ID
#  context_id            :string(255)      not null - legacy composed identifier
#                                            (Course ID + Resource Link ID); will
#                                            be dropped once the binding flow ships
#  lms_id                :string(255)      not null
#  lms_family            :string(255)      e.g. 'canvas'
#  lti_course_binding_id :integer          - replaces the legacy context_id
#  roles                 :text(65535)      - serialized array of LTI roles
#  linked_at             :datetime         - set when user_id populated
#

# Per-user, per-binding link between a Dashboard User and an LMS user
# identity. May exist with `user_id=nil` when a Canvas member is known
# from NRPS but hasn't yet linked a Wikipedia account via Dashboard OAuth.
#
# The map is 1:1 in both directions within a binding, enforced by two unique
# indexes: (user_lti_id, binding) and (binding, user_id). The second one is why
# two Canvas members in a course can't both resolve to one Wikipedia account,
# which would post the same progress at both of their gradebook rows.
# `user_id = NULL` is exempt (MySQL treats NULLs as distinct), so a course can
# hold any number of not-yet-connected members.
#
# The link is also write-once: a launch may establish one but never move one, so
# a shared launch URL can't reassign a Canvas identity to whoever is signed in.
# Clearing a bad link is a staff operation. See
# LtiSession#reject_conflicting_link!.
class LtiContext < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :lti_course_binding, optional: true

  serialize :roles, type: Array

  validates :user_lti_id, :lms_id, presence: true

  scope :linked, -> { where.not(user_id: nil) }
  scope :unlinked, -> { where(user_id: nil) }

  def linked?
    user_id.present?
  end

  # Whether this membership's LMS roles mark it as course staff
  # (instructor/administrator) rather than a learner. Mirrors LtiSession's role
  # classification.
  def instructor?
    LtiSession.role_match?(roles, LtiSession::INSTRUCTOR_ROLES)
  end

  # Whether this membership is a learner. Deliberately not `!instructor?` —
  # Canvas observers and designers are neither, and the sets that drive grade
  # pushes and the "synced students" metric must exclude them rather than treat
  # them as students by default. See LtiSession::LEARNER_ROLES.
  def learner?
    !instructor? && LtiSession.role_match?(roles, LtiSession::LEARNER_ROLES)
  end
end
