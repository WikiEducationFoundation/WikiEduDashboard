# frozen_string_literal: true

# The link between a Dashboard user and one LMS identity within a course, for the
# launch path. Split out of LtiSession, which had grown three responsibilities
# (reading launch claims, resolving the binding, and this).
#
# The map is 1:1 in both directions within a binding and WRITE-ONCE: a launch may
# establish a link but never move one. Two Canvas members sharing one Wikipedia
# account would make grade sync post the same progress at both of their gradebook
# rows; and because the ltik travels in the URL, a launch that moved an identity
# onto whoever happens to be signed in would let a student hand their launch link
# to someone else and have that person's Dashboard progress feed the student's own
# Canvas grade. Clearing a bad link is a staff operation.
#
# Three operations, deliberately distinct:
#
#   - #refresh_existing_link — automatic on every launch. LMS role changes have
#     to keep propagating.
#   - #link_conflict — a query, so a view can ask why linking isn't on offer
#     before showing a button that would fail.
#   - #link_lti_user — the write, which only the user's own approval triggers
#     (LtiLaunchController#connect_identity). It used to happen as a side effect
#     of any launch carrying a session, which silently connected whichever
#     Dashboard account the browser happened to be signed into.
#
# The error classes live on LtiSession because callers rescue them by that name.
class LtiLaunchLinker
  include RetryOnUniqueRace

  def initialize(lti_session)
    @session = lti_session
  end

  # Idempotently records that `current_user` is the Dashboard user for this LMS
  # identity within the binding. Refreshes the launch's roles each time so they
  # stay current; no name or email is read (anonymized posture).
  def link_lti_user(current_user, binding: nil)
    binding ||= @session.find_or_create_binding!
    retry_on_unique_race do
      context = LtiContext.find_or_initialize_by(user_lti_id: @session.user_lti_id,
                                                lti_course_binding_id: binding.id)
      reject_conflicting_link!(context, current_user, binding)
      apply_context_attributes(context, current_user)
      context.linked_at ||= Time.current
      context.save!
      context
    end
  end

  # This launch's identity IF it is already linked to `current_user`, roles
  # refreshed. nil when there is no link yet — an NRPS-discovered row (user_id
  # nil) counts as no link, so the launch asks and the approval fills it in.
  def refresh_existing_link(current_user, binding: nil)
    binding ||= @session.find_or_create_binding!
    context = LtiContext.find_by(user_lti_id: @session.user_lti_id,
                                 lti_course_binding_id: binding.id)
    return if context.nil? || context.user_id.nil? || context.user_id != current_user.id

    apply_context_attributes(context, current_user)
    context.save!
    context
  end

  # Why this launch can't create a link, established without writing anything:
  #
  #   :identity_taken — this LMS identity already belongs to a different
  #     Dashboard account (the person at the keyboard connected another one
  #     before). Self-service remedy: sign back in as that account.
  #   :user_taken — this Dashboard account already holds a different LMS identity
  #     in this course. Staff have to clear it.
  #
  # nil when the link is available, or already this user's.
  def link_conflict(current_user, binding: nil)
    binding ||= @session.find_or_create_binding!
    context = LtiContext.find_by(user_lti_id: @session.user_lti_id,
                                 lti_course_binding_id: binding.id)
    return :identity_taken if context&.user_id.present? && context.user_id != current_user.id

    others = LtiContext.where(lti_course_binding_id: binding.id, user_id: current_user.id)
    others = others.where.not(id: context.id) if context&.persisted?
    others.exists? ? :user_taken : nil
  end

  private

  # The enforcing half of #link_conflict, raising at the moment of the write so a
  # race that slipped between the check and the save can't create a second link.
  def reject_conflicting_link!(context, current_user, binding)
    if context.user_id.present? && context.user_id != current_user.id
      raise LtiSession::DuplicateUserLinkError,
            "LMS identity #{@session.user_lti_id} in binding #{binding.id} is already " \
            "linked to user #{context.user_id}, not #{current_user.id}"
    end

    conflicts = LtiContext.where(lti_course_binding_id: binding.id, user_id: current_user.id)
    conflicts = conflicts.where.not(id: context.id) if context.persisted?
    return unless conflicts.exists?

    raise LtiSession::ConflictingLinkError,
          "user #{current_user.id} is already linked to another LMS identity " \
          "in binding #{binding.id}"
  end

  def apply_context_attributes(context, current_user)
    context.user = current_user
    context.lms_id = @session.lms_id
    context.lms_family = @session.lms_family
    # The legacy concatenated identifier persisted on the existing
    # `lti_contexts.context_id` column. Retained until the column is dropped in
    # a follow-up PR.
    context.context_id = "#{@session.lms_context_id}::#{@session.lms_resource_link_id}"
    context.roles = @session.user_roles
  end
end
