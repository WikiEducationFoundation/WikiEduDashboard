# frozen_string_literal: true

# Turns a verified LTI 1.1 launch's raw OAuth form parameters into the
# idtoken-shaped hash the rest of the integration reads, so nothing downstream
# of LtiSession can tell a launch we terminated from one LTIAAS did.
#
# The shape is not invented: it is what LTIAAS's normalized idtoken actually
# contained for a real Canvas 1.1 launch, captured from canvas.wikiedu.org on
# 2026-09-15 and recorded in docs/canvas_dev_setup.md. Notably a 1.1 launch has
# no `platform.id` and no `platform.url`; LtiSession falls back to the Canvas
# instance guid for the first and to the launch's return URL for the second.
class NormalizeLtiLegacyLaunch
  # LTIAAS's label for a legacy launch, and what LtiSession#legacy? tests
  # against. Keeping it identical means the version recorded on bindings is the
  # same whichever terminator handled the launch.
  LTI_VERSION = '1.2.0'

  attr_reader :idtoken

  # `course_id` is the claim carried by the key the launch authenticated with:
  # the Dashboard course whose instructor issued it. It rides under our own
  # `dashboard` key, which LTIAAS never sends, so it cannot be confused with a
  # real LTI claim. LtiSession uses it to bind the course on the first launch,
  # which is what spares the instructor the setup picker.
  def initialize(params, course_id: nil)
    @params = params
    @course_id = course_id
    @idtoken = build
  end

  private

  def build
    {
      'ltiVersion' => LTI_VERSION,
      'user' => { 'id' => @params['user_id'], 'roles' => roles },
      'platform' => platform,
      'launch' => launch,
      'custom' => custom,
      'services' => services,
      'dashboard' => { 'courseId' => @course_id }
    }
  end

  # Canvas sends a comma-separated list, unnormalized. Passed through as-is
  # rather than mapped to the 1.3 vocabulary (which is also what LTIAAS did),
  # so the role tables accept both forms.
  def roles
    @params['roles'].to_s.split(',').map(&:strip).reject(&:empty?)
  end

  def platform
    {
      'guid' => @params['tool_consumer_instance_guid'],
      'name' => @params['tool_consumer_instance_name'],
      'version' => @params['tool_consumer_info_version'],
      'productFamilyCode' => @params['tool_consumer_info_product_family_code']
    }
  end

  def launch
    {
      'type' => VerifyLtiLegacyLaunch::MESSAGE_TYPE,
      'context' => { 'id' => @params['context_id'], 'label' => @params['context_label'],
                     'title' => @params['context_title'] },
      'resourceLink' => { 'id' => @params['resource_link_id'],
                          'title' => @params['resource_link_title'] },
      'presentation' => { 'documentTarget' => @params['launch_presentation_document_target'],
                          'locale' => @params['launch_presentation_locale'],
                          'returnUrl' => @params['launch_presentation_return_url'] }
    }
  end

  # `custom_` parameters, with the prefix stripped, at the top level — which is
  # where LtiSession looks for them.
  def custom
    @params.each_with_object({}) do |(name, value), customs|
      next unless name.start_with?('custom_')

      customs[name.delete_prefix('custom_')] = value
    end
  end

  # There are none under 1.1 in companion mode: no roster service, no line
  # items, no scores. Stated explicitly so the sync services and the
  # deep-linking guards see the same "unavailable" they would from LTIAAS.
  def services
    { 'namesAndRoles' => { 'available' => false },
      'assignmentAndGrades' => { 'available' => false },
      'deepLinking' => { 'available' => false },
      'outcomes' => { 'available' => false } }
  end
end
