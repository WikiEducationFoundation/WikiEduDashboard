# frozen_string_literal: true

# Represents a single LTI launch from an LMS (currently Canvas, via LTIAAS).
# Active for the duration of one HTTP request that began with a Canvas click;
# uses launch-bound LTIK auth.
#
# Normally an LTI 1.3 launch, fetched from LTIAAS. An LTI 1.1 launch arrives
# with a token we minted ourselves, carrying an idtoken we normalized into the
# same shape (see NormalizeLtiLegacyLaunch), and reads through this same class;
# `ltiVersion` is "1.2.0" for those, which is what #legacy? tests. What a legacy
# launch can do is much less: launch, identity linking and enrollment only; no
# roster service, no line items, no grade passback. Callers of the 1.3-only
# surfaces check #legacy? and refuse.
#
# Background jobs that need NRPS or AGS without an active launch should use
# LtiServiceSession instead.
class LtiSession
  # LTI 1.3 context roles that mean course staff. Canvas sends the base
  # `membership#Instructor` for both TeacherEnrollment and TaEnrollment (a TA
  # additionally carries the `membership/Instructor#TeachingAssistant`
  # sub-role), so both land here.
  #
  # `membership#Mentor` is deliberately NOT here. Canvas maps
  # ObserverEnrollment — typically a guardian or an auditor — to Mentor, so
  # listing it made every Canvas observer a Dashboard *instructor*: they saw the
  # instructor status panel and its sync controls, and once they connected a
  # Wikipedia account LtiMemberLinker enrolled them as an instructor on the
  # course. See Canvas's role table:
  # https://developerdocs.instructure.com/services/canvas/external-tools/file.canvas_roles
  INSTRUCTOR_ROLES = [
    'membership#Administrator',
    'membership#Instructor'
  ].freeze

  # The only role we treat as a learner. An allowlist, not "anything that isn't
  # staff": Canvas also sends Mentor (observers) and ContentDeveloper
  # (designers), a launch can arrive with no roles claim at all, and a role we
  # don't recognize must not become an enrollment by default.
  LEARNER_ROLES = ['membership#Learner'].freeze

  # The LTI 1.1 forms of the same classification, for legacy launches whose
  # roles LTIAAS hands through unnormalized: the spec's `urn:lti:role:ims/lis/…`
  # context-role URNs and the bare short names it allows for them. Matched
  # exactly rather than by suffix, so the institution-level
  # `urn:lti:instrole:ims/lis/Instructor` and the system-level
  # `urn:lti:sysrole:…` forms don't classify as course staff — mirroring the
  # 1.3 table, where `institution/person#Instructor` isn't accepted either.
  #
  # TeachingAssistant is listed because Canvas's 1.1 TaEnrollment sends ONLY the
  # TA role (no base Instructor), where its 1.3 launch sends both and the TA
  # counts as staff through the base role; listing it keeps a TA classified the
  # same way under either version. Mentor and Observer stay out for the reason
  # given above: Canvas's 1.1 ObserverEnrollment sends `urn:lti:role:ims/lis/Mentor`
  # (with `urn:lti:instrole:ims/lis/Observer`). Sub-roles such as
  # `…/Instructor/PrimaryInstructor` are not listed; Canvas doesn't send them, and
  # an unlisted role lands in `unsupported_role?` rather than becoming staff.
  #
  # Written from the LTI 1.1 spec and Canvas's published role table, not yet
  # checked against a captured legacy launch — verify how LTIAAS actually
  # normalizes these before trusting the mapping in production.
  LEGACY_INSTRUCTOR_ROLES = %w[
    Instructor
    Administrator
    TeachingAssistant
    urn:lti:role:ims/lis/Instructor
    urn:lti:role:ims/lis/Administrator
    urn:lti:role:ims/lis/TeachingAssistant
  ].freeze
  LEGACY_LEARNER_ROLES = %w[Learner urn:lti:role:ims/lis/Learner].freeze

  # Stands in for the resource link id on a deep-linking request, which has
  # none. Context-scoped by the binding's unique index, so one row per Canvas
  # course rather than one per picker visit.
  DEEP_LINKING_RESOURCE_LINK_ID = 'lti:deep-linking-request'

  attr_reader :idtoken

  # Two kinds of launch token reach this class. An LTIAAS `ltik` (every LTI 1.3
  # launch) is exchanged for an idtoken over their API. Our own token (every
  # LTI 1.1 launch, since we terminate those ourselves) already carries the
  # normalized idtoken, so it is decoded rather than fetched. The prefix tells
  # them apart without attempting a decode first.
  def self.for_ltik(ltik)
    return new(idtoken: LtiLegacyLaunchToken.decode(ltik)) if LtiLegacyLaunchToken.ours?(ltik)

    new(ENV['LTIAAS_DOMAIN'], ENV['LTIAAS_API_KEY'], ltik)
  end

  def initialize(ltiaas_domain = nil, api_key = nil, ltik = nil, idtoken: nil)
    if idtoken
      @idtoken = idtoken
      return
    end

    @client = LtiaasClient.with_ltik(ltiaas_domain, api_key, ltik)
    @idtoken = @client.get('/api/idtoken')
  end

  def user_lti_id
    @idtoken['user']['id']
  end

  # Anonymized posture: the Dashboard never reads the launch's name/email (the
  # tool is registered so Canvas doesn't send them, and we don't consume them
  # even if a platform did). Identity comes from the student's Wikipedia OAuth.

  def user_roles
    @idtoken['user']['roles'] || []
  end

  def instructor?
    LtiSession.instructor_role?(user_roles)
  end

  # Staff wins when a launch carries both, which Canvas does for anyone holding
  # more than one enrollment in the course.
  def student?
    !instructor? && LtiSession.learner_role?(user_roles)
  end

  # Neither staff nor learner: a Canvas observer or designer, a role we don't
  # recognize, or a launch with no roles claim. These launches get read-only
  # views — never a Dashboard enrollment, never a grade.
  def unsupported_role?
    !instructor? && !student?
  end

  # The classification, shared with LtiContext and LtiMemberLinker so a
  # membership is read the same way whether it came from a launch or NRPS.
  # Both role vocabularies are accepted everywhere: the union of two allowlists
  # is still an allowlist, and a 1.3 platform never sends the 1.1 forms.
  def self.instructor_role?(roles)
    role_match?(roles, INSTRUCTOR_ROLES) || legacy_role_match?(roles, LEGACY_INSTRUCTOR_ROLES)
  end

  def self.learner_role?(roles)
    role_match?(roles, LEARNER_ROLES) || legacy_role_match?(roles, LEGACY_LEARNER_ROLES)
  end

  # LTI 1.3 roles: match on the vocabulary suffix.
  def self.role_match?(roles, suffixes)
    Array(roles).any? { |role| suffixes.any? { |suffix| role.to_s.end_with?(suffix) } }
  end

  # LTI 1.1 roles: exact matches only (see LEGACY_INSTRUCTOR_ROLES).
  def self.legacy_role_match?(roles, names)
    Array(roles).any? { |role| names.include?(role.to_s) }
  end

  # The `ltiVersion` LTIAAS reports for this launch. Absent from the
  # (pre-legacy) fixtures and from any older payload, so a missing value reads
  # as 1.3 — the only kind of launch that reached the Dashboard before legacy
  # support existed, and the kind whose absence must not start refusing
  # production launches. A real legacy launch always carries "1.2.0".
  def lti_version
    @idtoken['ltiVersion'].presence || LtiCourseBinding::LTI_1_3
  end

  # A legacy LTI 1.1 launch: launch-only companion mode. "Not 1.3" rather than
  # a "1.1" string match, because LTIAAS labels these "1.2.0".
  def legacy?
    lti_version != LtiCourseBinding::LTI_1_3
  end

  # Backwards-compatible alias for callers still on the old name.
  alias user_is_teacher? instructor?

  # The platform's identity, and the first half of a binding's key. On a 1.3
  # launch it is LTIAAS's per-registration platform id. A legacy launch has no
  # registration behind it (one global 1.1 key/secret for every LMS), so LTIAAS
  # sends no `platform.id`; what it does forward is the LMS's own
  # `tool_consumer_instance_guid`, as `platform.guid` — per Canvas root account,
  # which is exactly the per-institution scope the shared key would otherwise
  # lose (two institutions' course ids can't collide across it). Verified on a
  # real legacy launch, 2026-09-15. A launch that names neither is refused by
  # supported_lms? rather than failing the binding's validation with a 422.
  def lms_id
    @idtoken.dig('platform', 'id').presence || @idtoken.dig('platform', 'guid').presence
  end

  def lms_family
    @idtoken['platform']['productFamilyCode']
  end

  # Canvas is the only platform this integration has been built and tested
  # against: the deep-linking flow depends on Canvas's Modules placement, line
  # items are created with a Canvas-only AGS submission_type extension, and the
  # role classification is pinned to Canvas's enrollment mapping. So launches
  # fail closed on anything else rather than reaching that Canvas-shaped code
  # with a platform nobody has exercised. Widening this is a deliberate change,
  # not an accident of whatever a platform reports.
  #
  # Under LTI 1.1 this gate does more work: LTIAAS registers one global
  # consumer key/secret for every legacy LMS (their own example is Moodle), so
  # nothing on the LTIAAS side limits which platform can launch, and this
  # allowlist is the effective platform filter. Whether LTIAAS fills
  # `productFamilyCode` from a 1.1 launch's `tool_consumer_info_product_family_code`
  # is unverified — a legacy launch that fails here is the signal to find out.
  SUPPORTED_LMS_FAMILY = 'canvas'

  # A supported LMS is also an identified one: without a platform identity
  # there is nothing to key a binding or a context on (see #lms_id).
  def supported_lms?
    lms_family.to_s.casecmp(SUPPORTED_LMS_FAMILY).zero? && lms_id.present?
  end

  def lms_context_id
    @idtoken['launch']['context']['id']
  end

  # A deep-linking request carries no resource link of its own, so fall back
  # to a synthetic, context-stable key: the launch still needs a binding row
  # to hang a course off when the instructor links from the picker's
  # break-out flow (the only linking entry point when the course-navigation
  # tab is off). Reading it unguarded used to raise NoMethodError there.
  def lms_resource_link_id
    @idtoken.dig('launch', 'resourceLink', 'id').presence || DEEP_LINKING_RESOURCE_LINK_ID
  end

  def context_title
    @idtoken['launch']['context']['title']
  end

  # LTI 1.3 / LTIAAS surfaces the platform's public base URL on the
  # `platform` claim. A legacy launch carries none, but it does carry the
  # LMS's own return URL, whose origin is the same base URL — so the
  # course-page sidebar can still link back into Canvas for a 1.1 course.
  # A missing value just means the status component renders without a link.
  def platform_url
    @idtoken.dig('platform', 'url').presence || legacy_platform_url
  end

  def legacy_platform_url
    return unless legacy?

    uri = URI.parse(@idtoken.dig('launch', 'presentation', 'returnUrl').to_s)
    "#{uri.scheme}://#{uri.host}" if uri.scheme && uri.host
  rescue URI::InvalidURIError
    nil
  end

  def nrps_url
    @idtoken.dig('services', 'namesAndRoles', 'contextMembershipsUrl')
  end

  def ags_lineitems_url
    @idtoken.dig('services', 'assignmentAndGrades', 'lineItemsUrl') ||
      @idtoken.dig('services', 'assignmentAndGrades', 'lineitemsUrl')
  end

  # The single line-item URL for the assignment this launch came from. Per
  # LTIAAS docs this is `lineItemId` on the AGS service object, "present
  # only if there's only one line item ID associated with the current
  # context" — i.e. an assignment-context launch (the assignment_view
  # placement), not the course-navigation launch. We match it against
  # LtiLineItem#lineitem_id to identify which gradebook column was clicked,
  # then backfill `canvas_assignment_id` for fast lookups on later launches.
  # Older/alternate casings kept as a defensive fallback.
  def ags_lineitem_url
    @idtoken.dig('services', 'assignmentAndGrades', 'lineItemId') ||
      @idtoken.dig('services', 'assignmentAndGrades', 'lineItemUrl') ||
      @idtoken.dig('services', 'assignmentAndGrades', 'lineitemUrl')
  end

  # Canvas variable substitutions configured on the `assignment_view`
  # placement (custom_fields) arrive under the idtoken `custom` claim.
  # Blank on launches from placements that don't set them (e.g. the
  # course-navigation launch).
  def canvas_assignment_id
    @idtoken.dig('custom', 'canvas_assignment_id').presence
  end

  # Whether this deep-linking launch's placement accepts more than one
  # content item (Canvas: true from the Modules-page bulk placement, false
  # from assignment_selection). The processed idtoken omits the
  # deep-linking-settings claim, so this reads the raw JWT claims via a
  # second, lazy LTIAAS fetch. Defaults to single-item on any failure —
  # the mode every placement accepts.
  def accepts_multiple_content_items?
    return false if @client.nil? # a legacy launch never reaches deep linking

    settings = raw_idtoken['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings']
    settings.present? && settings['accept_multiple'].to_s == 'true'
  rescue StandardError
    false
  end

  # The deep-link resource marker (e.g. "Block:42" or "TrainingProgress") we
  # set on the content item, echoed back under the `custom` claim on launches
  # of the Canvas assignment created from it. Lets the first such launch bind
  # its line item to the Dashboard gradable. Blank on launches of assignments
  # we didn't create via deep linking.
  def deep_link_resource
    @idtoken.dig('custom', 'resource').presence
  end

  # The service-auth key captured from this launch's idtoken. Long-lived
  # but per LTIAAS docs should be refreshed into the binding on every
  # launch in case the underlying NRPS/AGS endpoint URLs have changed.
  # See https://docs.ltiaas.com/guides/api/authentication
  def service_key
    @idtoken.dig('services', 'serviceKey')
  end

  # The Dashboard course the launch's consumer key was issued for, present only
  # on a self-hosted LTI 1.1 launch. `dashboard` is our own key in the idtoken
  # we build; LTIAAS never sends one, so it cannot be confused with an LTI
  # claim. See #claim_course for what it is for.
  def claimed_course_id
    @idtoken.dig('dashboard', 'courseId')
  end

  # Identity linking — refreshing a link, the conflict query, and the write-once
  # creation — lives in its own collaborator (LtiLaunchLinker). This class had
  # grown three responsibilities: reading launch claims, resolving the binding,
  # and the link lifecycle, which is the one with policy in it. The error classes
  # stay here because callers rescue them by this name.
  delegate :link_lti_user, :refresh_existing_link, :link_conflict, to: :linker
  # Binding resolution is the second responsibility split out of this class;
  # see LtiBindingResolver.
  delegate :find_or_create_binding!, :bound_binding, to: :binding_resolver

  # Raised when this launch would change an existing link rather than create one:
  # either the launching Dashboard user already belongs to a different LMS
  # member of the course, or this LMS identity already belongs to a different
  # Dashboard user. Callers turn it into the "couldn't enroll you" view rather
  # than a 500.
  class ConflictingLinkError < StandardError; end

  # The distinguishable flavor of ConflictingLinkError: this LMS identity is
  # already linked to a *different* Dashboard account — i.e. the person at
  # the keyboard previously connected another account. Unlike the general
  # conflict it has a self-service remedy (sign back in with the account
  # that was connected first), so the setup flow names it separately.
  class DuplicateUserLinkError < ConflictingLinkError; end

  # Raised when a launch arrives from a platform this integration hasn't been
  # built for. See SUPPORTED_LMS_FAMILY.
  class UnsupportedLmsError < StandardError; end

  # Raised for a legacy (LTI 1.1) launch while Features.lti_legacy_launches? is
  # off. Fails closed like the platform gate: nothing downstream should run for
  # a launch kind the deployment hasn't opted into.
  class LegacyLaunchesDisabledError < StandardError; end

  private

  def raw_idtoken
    @raw_idtoken ||= @client.get('/api/idtoken?raw=true')
  end

  def linker
    @linker ||= LtiLaunchLinker.new(self)
  end

  def binding_resolver
    @binding_resolver ||= LtiBindingResolver.new(self)
  end
end
