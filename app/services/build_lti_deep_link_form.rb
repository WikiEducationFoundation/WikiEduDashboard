# frozen_string_literal: true

# Builds the LTI Deep Linking response for a deep-linking launch: assembles
# the content items and asks LTIAAS (POST /api/deeplinking/form) to return a
# self-submitting HTML form that POSTs the signed JWT back to the LMS,
# finalizing content selection. Exposes that form HTML via `#form`.
#
# Construct with the launch's `ltik` (deep linking only accepts LTIK auth).
#
# PROBE STUB: `content_items` currently returns a single synthetic item so
# we can confirm on staging that a deep-link-created resource link delivers
# `lineItemId` (and whether our `resource` marker survives) on subsequent
# launches. The real per-assignment picker — instructor selects one exercise
# Block, which becomes one content item — replaces `content_items` once the
# probe confirms the plumbing.
class BuildLtiDeepLinkForm
  attr_reader :form

  def initialize(ltik:)
    @ltik = ltik
    perform
  end

  private

  def perform
    client = LtiaasClient.with_ltik(ENV['LTIAAS_DOMAIN'], ENV['LTIAAS_API_KEY'], @ltik)
    result = client.post('/api/deeplinking/form', contentItems: content_items)
    @form = result['form']
  end

  # One synthetic content item carrying both a `lineItem` (so Canvas auto-
  # creates the tied gradebook column) and a `resource` marker passed two
  # ways — as a launch-url query param and as a content-item `custom` value —
  # so the diagnostic can see which (if either) survives onto the resource-
  # link launch. No PII; `probe` is a literal tag.
  def content_items
    launch_url = "https://#{ENV['LTIAAS_DOMAIN']}/lti/launch?resource=probe"
    [{
      type: 'ltiResourceLink',
      url: launch_url,
      title: 'WED deep-link probe',
      custom: { resource: 'probe' },
      lineItem: { scoreMaximum: 1.0, label: 'WED deep-link probe', tag: 'probe' }
    }]
  end
end
