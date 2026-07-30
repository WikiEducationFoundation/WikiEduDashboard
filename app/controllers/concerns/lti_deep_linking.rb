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
# create duplicates. Each accepted selection is also reserved with a pending
# LtiLineItem row before the form is returned, closing the window between
# form and discovery in which a duplicate submission would otherwise still
# look offerable.
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
    return render_launch_error_or_redirect if params[:ltik].blank?

    @ltik = params[:ltik]
    @lti_session = build_lti_session(@ltik)
    return render_deep_link_forbidden unless @lti_session.instructor?

    @binding = @lti_session.bound_binding
    # Not linked yet: render the same "not yet linked" landing the course-nav
    # launch shows, so the instructor's next step is the obvious "Open the
    # Wiki Education Dashboard" button (there's nothing to pick until the
    # course is linked there first).
    return render_not_linked_landing if @binding.nil?

    prepare_picker
    render 'lti_launch/deep_link_picker', layout: 'lti_iframe'
  end

  def render_not_linked_landing
    @show_not_linked_notice = true
    render 'lti_launch/sign_in_to_continue', layout: 'lti_iframe'
  end

  def deep_link_select
    return render_launch_error_or_redirect if params[:ltik].blank?

    @lti_session = build_lti_session(params[:ltik])
    return render_deep_link_forbidden unless @lti_session.instructor?

    binding = @lti_session.bound_binding
    gradables = chosen_gradables(binding)
    return head :unprocessable_entity unless selection_accepted?(binding, gradables)

    @deep_link_form = BuildLtiDeepLinkForm.new(ltik: params[:ltik], gradables:).form
    schedule_line_item_discovery(binding)
    render 'lti_launch/deep_link_form', layout: 'lti_iframe'
  end

  private

  # The picker placements are reachable by non-instructor course roles too
  # (a Canvas observer or designer). Only INSTRUCTOR_ROLES may import, but a
  # bare `head :forbidden` renders as a blank page inside Canvas's picker
  # modal — so keep the 403 and explain the refusal in-frame. Which roles
  # count as instructors is the operator's LtiSession::INSTRUCTOR_ROLES
  # policy, deliberately untouched here.
  def render_deep_link_forbidden
    render 'lti_launch/deep_link_forbidden', layout: 'lti_iframe', status: :forbidden
  end

  # Multi-select when the placement takes multiple content items. Gradables
  # already backed by an active gradebook column are off the menu — picking
  # one would create a duplicate Canvas assignment (this also removes the
  # auto-created trainings roll-up from the offer).
  def prepare_picker
    @accept_multiple = @lti_session.accepts_multiple_content_items?
    @gradables = offerable_gradables(@binding)
    @all_added = @gradables.empty? && DeepLinkableGradables.new(@binding.course).result.any?
  end

  # The gradables matching the submitted selection (`resources[]` from the
  # multi picker, `resource` from the single one), re-derived from the bound
  # course so only that course's own gradables are accepted. Empty if
  # unbound, nothing was picked, or ANY submitted resource isn't offerable —
  # reject the whole request rather than silently dropping entries.
  #
  # "Offerable" has to mean the same thing here as it did when the picker was
  # rendered, which is why the taken-column exclusion is recomputed rather than
  # trusted from the form. Validating only course membership let a replayed or
  # tampered POST ask for a gradable that already has a Canvas assignment,
  # producing a second column with the same tag — and two columns for one
  # gradable is exactly the duplicate the line-item uniqueness index now refuses
  # to record, so the extra column would be stranded in the gradebook.
  def chosen_gradables(binding)
    return [] if binding.nil?

    requested = Array(params[:resources]).presence || [params[:resource]].compact
    requested = requested.uniq
    return [] if requested.empty?

    offered = offerable_gradables(binding).index_by(&:resource)
    chosen = requested.map { |resource| offered[resource] }
    chosen.include?(nil) ? [] : chosen
  end

  # Every refusal is the same bare 422: a blank or tampered selection, a
  # multi-item response to a single-item placement, or a reservation lost to
  # a concurrent duplicate of this request (a double-submit or replayed POST,
  # whose losing response is unseen inside Canvas's picker anyway). The
  # reservation must succeed before the deep-link form is built: the pending
  # rows it creates are what make these gradables read as taken to any
  # concurrent duplicate.
  def selection_accepted?(binding, gradables)
    gradables.present? && !too_many_for_placement?(gradables) &&
      ReserveLtiLineItems.new(binding:, gradables:).reserved
  end

  # The set the picker would offer right now: the course's gradables minus any
  # already backed by an active row — a bound gradebook column or a pending
  # reservation, which counts as taken by design.
  def offerable_gradables(binding)
    taken = binding.lti_line_items.active.pluck(:gradable_type, :gradable_id).to_set
    DeepLinkableGradables.new(binding.course).result
                         .reject { |g| taken.include?([g.gradable_type, g.gradable_id]) }
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
