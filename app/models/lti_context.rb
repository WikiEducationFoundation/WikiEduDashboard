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
#  email                 :string(255)
#  name                  :string(255)
#  roles                 :text(65535)      - serialized array of LTI roles
#  linked_at             :datetime         - set when user_id populated
#

# Per-user, per-binding link between a Dashboard User and an LMS user
# identity. May exist with `user_id=nil` when a Canvas member is known
# from NRPS but hasn't yet linked a Wikipedia account via Dashboard OAuth.
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
end
