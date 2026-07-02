# frozen_string_literal: true

require 'cgi'

# Builds the LTI Deep Linking response for a deep-linking launch: assembles a
# single content item for the gradable the instructor picked and asks LTIAAS
# (POST /api/deeplinking/form) to return a self-submitting HTML form that POSTs
# the signed JWT back to the LMS, finalizing content selection. Exposes that
# form HTML via `#form`.
#
# Construct with the launch's `ltik` (deep linking only accepts LTIK auth) and
# the chosen `gradable` (a DeepLinkableGradables::Gradable). The content item
# carries a `lineItem` (so Canvas auto-creates the tied gradebook column) and
# the gradable's `resource` marker — both as a launch-url query param and as a
# content-item `custom` value — so the resource-link launch can be bound back
# to its Dashboard gradable. No PII crosses to Canvas: only the resource key
# (e.g. `Block:42`) and the gradable's label.
class BuildLtiDeepLinkForm
  DEFAULT_SCORE_MAXIMUM = 1.0

  attr_reader :form

  def initialize(ltik:, gradable:)
    @ltik = ltik
    @gradable = gradable
    perform
  end

  private

  def perform
    client = LtiaasClient.with_ltik(ENV['LTIAAS_DOMAIN'], ENV['LTIAAS_API_KEY'], @ltik)
    result = client.post('/api/deeplinking/form', contentItems: content_items)
    @form = result['form']
  end

  def content_items
    [{
      type: 'ltiResourceLink',
      url: launch_url,
      title: @gradable.label,
      custom: { resource: @gradable.resource },
      lineItem: { scoreMaximum: DEFAULT_SCORE_MAXIMUM, label: @gradable.label,
                  tag: @gradable.resource }
    }]
  end

  def launch_url
    "https://#{ENV['LTIAAS_DOMAIN']}/lti/launch?resource=#{CGI.escape(@gradable.resource)}"
  end
end
