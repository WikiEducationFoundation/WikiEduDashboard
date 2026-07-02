# frozen_string_literal: true

# Pulls the LMS course roster via NRPS for one LtiCourseBinding and runs
# LtiMemberLinker on each member. Idempotent: every successful sync
# advances `last_roster_sync_at`; failures are surfaced via raised
# exceptions so Sidekiq can retry transient failures and dead-letter
# authoritative ones.
#
# A binding without a stored serviceKey is a no-op (we haven't seen a
# launch from this Canvas course yet, so we don't have credentials).
class SyncLtiRoster
  attr_reader :binding

  def initialize(binding)
    @binding = binding
    perform
  end

  private

  def perform
    return if @binding.ltiaas_service_credentials.blank?

    service = LtiServiceSession.new(@binding)
    members = service.fetch_memberships
    members.each { |member| link_member(member) }
    @binding.update!(last_roster_sync_at: Time.current)
  end

  def link_member(member)
    LtiMemberLinker.new(@binding, member)
  rescue StandardError => e
    Sentry.capture_exception(
      e,
      extra: { binding_id: @binding.id, user_lti_id: member[:user_lti_id] }
    )
  end
end
