# frozen_string_literal: true

# Resolving a launch to its LtiCourseBinding. Split out of LtiSession the same
# way LtiLaunchLinker was: that class had grown three responsibilities —
# reading launch claims, resolving the binding, and the link lifecycle — and
# this is the second. LtiSession delegates, so callers are unchanged.
class LtiBindingResolver
  include RetryOnUniqueRace

  def initialize(lti_session)
    @session = lti_session
  end

  # Looks up or creates the LtiCourseBinding for this launch. A binding models
  # a Canvas *course*, so it is keyed on (lms_id, lms_context_id) alone — every
  # launch from that Canvas course, whether nav, assignment or deep-link, and
  # whether before or after linking, resolves to the same row. Keying on the
  # resource link as well used to mint a throwaway row per assignment: the
  # student's LtiContext landed somewhere grade sync never reads, the bound
  # row's service credentials went stale, and a pre-link course could end up
  # with several rows competing to be the bound one.
  #
  # `course_id` stays nil until the controller's setup flow populates it, or
  # until a self-hosted LTI 1.1 key claims it (see LtiCourseBinding#claim_course).
  # Snapshot fields (service_key, NRPS/AGS URLs, lms_family, resource link, LTI
  # version) are refreshed on every launch so background-job credentials track
  # the most recent launch.
  #
  # A legacy launch records its version and nothing for the service side: its
  # NRPS/AGS URLs are absent anyway, and no key is persisted — the legacy
  # `services.legacyServiceKey` is per-user and only good for Basic Outcomes,
  # which the integration deliberately doesn't do.
  #
  # find-then-create is not atomic: two first launches from the same Canvas
  # course (two instructors, or a nav launch racing a deep-link launch) can both
  # find no row, and the unique index on (lms_id, lms_context_id) then makes one
  # of the saves raise. Retry once — the second pass finds the winner's row and
  # refreshes the same snapshot onto it, so the losing launch continues instead
  # of rendering a 500 inside the Canvas iframe.
  def find_or_create_binding!
    retry_on_unique_race do
      binding = LtiCourseBinding.find_or_initialize_by(lms_id:, lms_context_id:)
      binding.assign_attributes(
        lms_resource_link_id: @session.lms_resource_link_id, lms_family: @session.lms_family,
        nrps_url: @session.nrps_url, ags_lineitems_url: @session.ags_lineitems_url,
        lms_context_title: @session.context_title, lms_platform_url: @session.platform_url,
        lti_version: @session.lti_version
      )
      binding.ltiaas_service_credentials = service_key if service_key.present? && !@session.legacy?
      binding.claim_course(@session.claimed_course_id)
      binding.save!
      binding
    end
  end

  # This launch's binding, but only once it has a Dashboard course — callers use
  # it as "is this Canvas course linked yet?" and rely on the nil. Unlike
  # find_or_create_binding! it never creates a row, so a read-only path (the
  # anonymous launch views, the deep-link picker) can ask without side effects.
  # The (lms_id, lms_context_id) key is unique, so this is at most one row.
  def bound_binding
    LtiCourseBinding.where(lms_id:, lms_context_id:)
                    .where.not(course_id: nil).first
  end

  private

  delegate :lms_id, :lms_context_id, :service_key, to: :@session
end
