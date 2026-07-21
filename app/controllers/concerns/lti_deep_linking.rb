# frozen_string_literal: true

# Deep Linking actions for the LTI flow, mixed into LtiLaunchController.
# LTIAAS forwards an LtiDeepLinkingRequest (from the assignment_selection /
# link_selection / module_index_menu_modal placements) to #deep_link, which
# renders a picker of the bound course's gradables — multi-select when the
# placement accepts multiple content items (Canvas's Modules-page bulk flow),
# single-choice otherwise. The instructor's choice posts to #deep_link_select,
# which returns one content item per picked gradable so Canvas creates
# assignments tied to our tool (resource link + AGS line item) — giving later
# launches the `lineItemId` the assignment_view drill-down resolves.
# Already-column-backed gradables are excluded from the offer so re-running
# the picker (or running it after the sync auto-created columns) can't
# create duplicates.
#
# Lives in a concern so the shared launch plumbing (build_lti_session,
# allow_iframe, the canvas-integration flag gate) stays in one place while
# keeping LtiLaunchController within its length budget.
module LtiDeepLinking
  extend ActiveSupport::Concern

  included do
    after_action :allow_iframe, only: %i[deep_link deep_link_select]
    # The picker submits back to us from inside the Canvas iframe, where the
    # dashboard session cookie is partitioned away. The launch is authenticated
    # by the ltik (validated by LTIAAS), not the Rails session, so session-based
    # CSRF protection neither applies nor can succeed here.
    skip_before_action :verify_authenticity_token, only: :deep_link_select
  end

  def deep_link
    return redirect_to errors_login_error_path if params[:ltik].blank?

    @ltik = params[:ltik]
    @lti_session = build_lti_session(@ltik)
    return head :forbidden unless @lti_session.instructor?

    @binding = @lti_session.bound_binding
    return render 'lti_launch/deep_link_unbound', layout: 'lti_iframe' if @binding.nil?

    prepare_picker
    render 'lti_launch/deep_link_picker', layout: 'lti_iframe'
  end

  def deep_link_select
    return redirect_to errors_login_error_path if params[:ltik].blank?

    @lti_session = build_lti_session(params[:ltik])
    return head :forbidden unless @lti_session.instructor?

    binding = @lti_session.bound_binding
    gradables = chosen_gradables(binding)
    return head :unprocessable_entity if gradables.blank?
    return head :unprocessable_entity if too_many_for_placement?(gradables)

    @deep_link_form = BuildLtiDeepLinkForm.new(ltik: params[:ltik], gradables:).form
    schedule_line_item_discovery(binding)
    render 'lti_launch/deep_link_form', layout: 'lti_iframe'
  end

  private

  # Multi-select when the placement takes multiple content items. Gradables
  # already backed by an active gradebook column are off the menu — picking
  # one would create a duplicate Canvas assignment (this also removes the
  # auto-created trainings roll-up from the offer).
  def prepare_picker
    @accept_multiple = @lti_session.accepts_multiple_content_items?
    offered = DeepLinkableGradables.new(@binding.course).result
    @gradables = offered.reject { |gradable| taken_keys.include?(gradable_key(gradable)) }
    @all_added = offered.any? && @gradables.empty?
  end

  def taken_keys
    @taken_keys ||= @binding.lti_line_items.active
                            .pluck(:gradable_type, :gradable_id).to_set
  end

  def gradable_key(gradable)
    [gradable.gradable_type, gradable.gradable_id]
  end

  # The gradables matching the submitted selection (`resources[]` from the
  # multi picker, `resource` from the single one), re-derived from the bound
  # course so only that course's own gradables are accepted. Empty if
  # unbound, nothing was picked, or ANY submitted resource isn't offerable —
  # reject the whole request rather than silently dropping entries.
  def chosen_gradables(binding)
    return [] if binding.nil?

    requested = Array(params[:resources]).presence || [params[:resource]].compact
    requested = requested.uniq
    return [] if requested.empty?

    offered = DeepLinkableGradables.new(binding.course).result.index_by(&:resource)
    chosen = requested.map { |resource| offered[resource] }
    chosen.include?(nil) ? [] : chosen
  end

  # A multi-item response to a single-item placement would be rejected by
  # the platform; fail fast on our side instead.
  def too_many_for_placement?(gradables)
    gradables.length > 1 && !@lti_session.accepts_multiple_content_items?
  end

  # Canvas creates the assignment(s) as soon as the returned form submits;
  # a follow-up sync discovers the new columns (by tag) and binds local rows
  # so grade sync and the picker's taken-list don't depend on each column
  # being launched first.
  def schedule_line_item_discovery(binding)
    LtiLineItemSyncWorker.perform_in(2.minutes, binding.id) if binding
  end
end
