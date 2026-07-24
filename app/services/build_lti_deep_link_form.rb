# frozen_string_literal: true

require 'cgi'

# Builds the LTI Deep Linking response for a deep-linking launch: assembles
# one content item per gradable the instructor picked and asks LTIAAS
# (POST /api/deeplinking/form) to return a self-submitting HTML form that POSTs
# the signed JWT back to the LMS, finalizing content selection. Exposes that
# form HTML via `#form`.
#
# A single-item selection serves the assignment_selection placement; the
# Modules-page bulk placement (module_index_menu_modal) accepts many items at
# once — Canvas creates a module and one assignment per item.
#
# Construct with the launch's `ltik` (deep linking only accepts LTIK auth) and
# the chosen `gradables` (DeepLinkableGradables::Gradable list). Each content
# item carries a `lineItem` (so Canvas auto-creates the tied gradebook column)
# and the gradable's `resource` marker — both as a launch-url query param and
# as a content-item `custom` value — so the resource-link launch can be bound
# back to its Dashboard gradable. No PII crosses to Canvas: only the resource
# key (e.g. `Block:42`), the gradable's label, and the fixed description.
class BuildLtiDeepLinkForm
  DEFAULT_SCORE_MAXIMUM = 1.0

  attr_reader :form

  def initialize(ltik:, gradables:)
    @ltik = ltik
    @gradables = Array(gradables)
    perform
  end

  private

  # Canvas names the module it creates for a bulk response from this custom
  # claim (falls back to "New Content From App" without it).
  MODULE_NAME_CLAIM = 'https://canvas.instructure.com/lti/module_name'

  def perform
    client = LtiaasClient.with_ltik(ENV['LTIAAS_DOMAIN'], ENV['LTIAAS_API_KEY'], @ltik)
    @form = request_form(client, module_name: true)['form']
  rescue LtiaasClient::LtiaasClientError
    # LTIAAS hasn't documented pass-through of the Canvas module_name claim;
    # if it rejects the extra field, retry without it — the import matters
    # more than the module's name (Canvas falls back to its default).
    @form = request_form(client, module_name: false)['form']
  end

  def request_form(client, module_name:)
    body = { contentItems: content_items }
    body[MODULE_NAME_CLAIM] = I18n.t('lti.deep_link.module_name') if module_name
    client.post('/api/deeplinking/form', body)
  end

  def content_items
    @gradables.map { |gradable| content_item_for(gradable) }
  end

  # No `text`/description on any item: a baked-in description goes stale the
  # moment the Dashboard timeline changes, and Canvas renders an external-tool
  # assignment with an empty description cleanly (verified on staging) — so
  # the launched iframe carries all descriptive content instead (operator
  # decision 2026-07-21).
  def content_item_for(gradable)
    {
      type: 'ltiResourceLink',
      url: launch_url(gradable),
      title: gradable.label,
      custom: { resource: gradable.resource },
      lineItem: { scoreMaximum: DEFAULT_SCORE_MAXIMUM, label: gradable.label,
                  tag: gradable.resource }
    }
  end

  def launch_url(gradable)
    "https://#{ENV['LTIAAS_DOMAIN']}/lti/launch?resource=#{CGI.escape(gradable.resource)}"
  end
end
