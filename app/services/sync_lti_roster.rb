# frozen_string_literal: true

# Pulls the LMS roster via NRPS for one LtiCourseBinding and runs
# LtiMemberLinker on each member.
#
# Failure semantics mirror SyncLtiGrades, in three tiers:
#
#   - Whole-run failures (network/5xx, rate limit, auth) abort the sync, record
#     `last_roster_sync_error`, leave `last_roster_sync_at` where it was, and
#     propagate so Sidekiq retries. These affect the whole roster, so recording
#     a successful recent sync when nothing was reconciled would be worse than
#     recording nothing.
#   - Per-member failures — bad or unexpected data for one membership — are
#     reported to Sentry and skipped. The run finishes and the timestamp advances,
#     because the rest of the roster really was reconciled — but it records how
#     many members it lost, so the run doesn't read as clean when it wasn't.
#   - Anything that isn't clearly one member's problem (a persistence error, a
#     bug in the linker) propagates too. Swallowing every StandardError per
#     member is how this used to report a fresh successful sync in the case where
#     every single member failed.
#   - A run where EVERY member failed on a per-member error aborts as a whole-run
#     failure, even though each individual error was in the skippable tier: a
#     roster that fails all the way through is a systemic problem wearing
#     per-member clothes (see #check_total_failure!).
#
# A binding without a stored serviceKey is a no-op (we haven't seen a
# launch from this Canvas course yet, so we don't have credentials).
class SyncLtiRoster
  # Same aborting tier as grade sync. Order matters at the rescue site:
  # LtiaasRateLimitError and LtiaasAuthError are LtiaasClientError subclasses.
  ABORTING_ERRORS = SyncLtiGrades::ABORTING_ERRORS

  # Per-member failures worth skipping past rather than failing the job. Narrow
  # on purpose: a member whose data the linker rejects (a validation failure on
  # the context, an unexpected NRPS shape) shouldn't stop the other members from
  # reconciling, but nothing broader is assumed to be one member's fault.
  MEMBER_ERRORS = [ActiveRecord::RecordInvalid,
                   ActiveRecord::RecordNotUnique,
                   KeyError,
                   TypeError,
                   NoMethodError].freeze

  # Raised when a roster failed one member at a time, all the way through. Its
  # own class so the recorded text names the condition rather than whichever
  # per-member error happened to be last.
  class TotalMemberFailureError < StandardError; end

  attr_reader :binding

  def initialize(binding)
    @binding = binding
    @failures = []
    perform
  end

  private

  def perform
    return if @binding.ltiaas_service_credentials.blank?

    service = LtiServiceSession.new(@binding)
    members = service.fetch_memberships
    members.each { |member| link_member(member) }
    check_total_failure!(members)
    @binding.update!(last_roster_sync_at: Time.current,
                     last_roster_sync_error: partial_failure_text(members))
    # Anything that escapes this far failed the whole run — the fetch, or a
    # per-member error outside MEMBER_ERRORS. Same shape as SyncLtiGrades:
    # record it before re-raising, otherwise a roster sync that dead-letters is
    # invisible on both status surfaces while `last_roster_sync_at` just stops
    # advancing.
  rescue StandardError => e
    record_aborted_sync(e)
    raise
  end

  def link_member(member)
    LtiMemberLinker.new(@binding, member)
  rescue *ABORTING_ERRORS
    raise # whole-run failure; let Sidekiq retry rather than half-syncing
  rescue *MEMBER_ERRORS => e
    report_member_failure(e, member)
  end

  def report_member_failure(error, member)
    @failures << "#{error.class}: #{error.message}"
    Sentry.capture_exception(
      error,
      extra: { binding_id: @binding.id, user_lti_id: member[:user_lti_id] }
    )
  end

  # Every member of a non-empty roster failing is not a roster of individually
  # bad memberships — it's one systemic failure repeated per member (a linker bug
  # raising NoMethodError on every row, an NRPS shape change turning every lookup
  # into a KeyError). Skipping past all of them and stamping a fresh
  # `last_roster_sync_at` is how an instructor ends up looking at a successful
  # sync with none of their students in it. Abort instead: the timestamp stays
  # put, the failure is recorded, and Sidekiq retries the run.
  def check_total_failure!(members)
    return unless members.any? && @failures.size == members.size

    raise TotalMemberFailureError,
          "all #{members.size} memberships failed; last: #{@failures.last}"
  end

  # A run that lost only some members still advances the timestamp — the rest of
  # the roster really was reconciled — but it must not read as clean, or the
  # missing students are invisible on both status surfaces. Recording the counts
  # sets `roster_sync_error?`, which is the "check the roster" signal the
  # instructor status view and the staff sidebar already render.
  def partial_failure_text(members)
    return nil if @failures.empty?

    "#{@failures.size} of #{members.size} memberships failed; last: #{@failures.last}"
      .truncate(SyncLtiGrades::ERROR_TEXT_LIMIT)
  end

  # A clean pass clears the field (in #perform); an aborted run records what
  # failed. As with the grade-sync field, only a boolean (`roster_sync_error?`)
  # is ever surfaced to users — the text is a diagnostic for staff, not copy.
  def record_aborted_sync(error)
    @binding.update!(last_roster_sync_error:
      "#{error.class}: #{error.message}".truncate(SyncLtiGrades::ERROR_TEXT_LIMIT))
  end
end
