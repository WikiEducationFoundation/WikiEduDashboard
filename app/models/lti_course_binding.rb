# frozen_string_literal: true
# == Schema Information
#
# Table name: lti_course_bindings
#
#  id                         :integer          not null, primary key
#  course_id                  :integer
#  lms_id                     :string(255)      not null
#  lms_family                 :string(255)
#  lms_context_id             :string(255)      not null
#  lms_resource_link_id       :string(255)      not null - snapshot of the launch
#                                                 that created/refreshed the row;
#                                                 NOT part of the row's identity
#                                                 (see the (lms_id,
#                                                 lms_context_id) unique index)
#  ltiaas_service_credentials :text(65535)
#  nrps_url                   :string(255)
#  ags_lineitems_url          :string(255)
#  gradebook_granularity      :string(255)      default("lumped"), not null
#  last_roster_sync_at        :datetime
#  last_grade_sync_at         :datetime
#  last_grade_sync_error      :text(65535)
#  lms_context_title          :string(255)      - LMS course title snapshot from
#                                                 the launch IdToken at binding
#                                                 creation; may drift if the
#                                                 instructor renames the course
#                                                 in the LMS.
#  lms_platform_url           :string(255)      - LMS base URL snapshot; used to
#                                                 build a click-through link to
#                                                 the LMS course view.
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#

# Persists the 1:1 binding between an LMS course and a Dashboard Course. Keyed
# on the LMS course — (lms_id, lms_context_id) — so every launch from that
# course, from any placement, resolves to one row. Created during an
# instructor's first launch from Canvas; the `course_id` may be nil briefly
# between binding creation and the instructor's setup-flow choice.
#
# `gradebook_granularity` is now effectively single-valued: the integration
# is **deep-link-first** — nothing is auto-created; the instructor imports the
# columns they want (account indicator, trainings roll-up, exercises) via the
# Canvas Modules "Import Wikipedia assignments" flow, and this service
# discovers + binds them. New bindings default to 'lumped' (the deep-link-first
# mode) and the setup step no longer offers a layout choice.
#
# 'standard' (auto-create roll-up + per-exercise) and 'per_block' (a column per
# block) remain valid values with working code, but are no longer user-
# selectable — retained only for any existing rows / tooling. Removing them
# entirely is a follow-up (see docs/canvas_integration_todos.md).
class LtiCourseBinding < ApplicationRecord
  GRADEBOOK_GRANULARITIES = %w[standard per_block lumped].freeze
  DEFAULT_GRANULARITY = 'lumped'

  # Human-readable LMS labels keyed by the LTI 1.3 `product_family_code`
  # values we expect to see. Unknown families fall back to a titleized
  # version of the family code in `lms_display_name`, so a new LMS
  # surfaces with a passable label automatically without a code change.
  LMS_DISPLAY_NAMES = { 'canvas' => 'Canvas' }.freeze

  belongs_to :course, optional: true
  has_many :lti_contexts, dependent: :destroy
  has_many :lti_line_items, dependent: :destroy

  # `courses.flags[:canvas_integration]` is a denormalized copy of "this course
  # has an LMS binding", kept so the course page can decide whether to fetch LMS
  # status — and whether the self-enroll alert applies — without an extra
  # request on every course view. Maintained here rather than at the call site
  # so it can't outlive the binding: set on the course a binding moves to,
  # cleared on the one it leaves, cleared when the binding is destroyed.
  # Best-effort by design (it's a cache): every server-side consumer re-checks
  # for a real binding plus the global feature gate.
  after_save :sync_linked_course_flags, if: :saved_change_to_course_id?
  after_destroy :clear_flag_on_bound_course

  validates :lms_id, :lms_context_id, :lms_resource_link_id, presence: true
  validates :gradebook_granularity, inclusion: { in: GRADEBOOK_GRANULARITIES }
  # A Dashboard course backs only one LMS course. There is a unique DB index on
  # course_id, but without this validation a duplicate surfaces as an uncaught
  # RecordNotUnique (500); the validation turns it into a handleable error.
  validates :course_id, uniqueness: { allow_nil: true }

  # A binding is identified by its LMS course, not by the resource link that
  # happened to create it (see LtiSession#find_or_create_binding!).
  def self.lookup(lms_id:, lms_context_id:)
    find_by(lms_id:, lms_context_id:)
  end

  def lms_display_name
    LMS_DISPLAY_NAMES[lms_family] || lms_family.to_s.titleize
  end

  def standard?
    gradebook_granularity == 'standard'
  end

  def lumped?
    gradebook_granularity == 'lumped'
  end

  def per_block?
    gradebook_granularity == 'per_block'
  end

  # The modes that roll every training into the single "Wikipedia trainings"
  # column. Block-backed columns in these modes grade only their exercise
  # modules — grading the block's trainings too would double-count them
  # against the roll-up and zero the exercise column until the surrounding
  # trainings happen to be complete.
  def rolled_up_trainings?
    !per_block?
  end

  # All student (non-staff) memberships that have linked a Wikipedia
  # account — the set that sync status counts and assignment rosters list.
  def linked_student_contexts
    lti_contexts.linked.reject(&:instructor?)
  end

  private

  def sync_linked_course_flags
    previous_course_id, current_course_id = saved_change_to_course_id
    clear_linked_flag(Course.find_by(id: previous_course_id))
    set_linked_flag(Course.find_by(id: current_course_id))
  end

  # Re-read rather than using the cached association: the flag may have been
  # written through a different Course instance (see sync_linked_course_flags),
  # so an association loaded before that write has a stale flags hash.
  def clear_flag_on_bound_course
    clear_linked_flag(Course.find_by(id: course_id))
  end

  def set_linked_flag(target)
    return if target.nil? || target.flags[:canvas_integration] == true

    target.flags[:canvas_integration] = true
    target.save
  end

  def clear_linked_flag(target)
    return if target.nil? || !target.flags.key?(:canvas_integration)

    target.flags.delete(:canvas_integration)
    target.save
  end
end
