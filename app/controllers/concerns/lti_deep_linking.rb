# frozen_string_literal: true

# Deep Linking actions for the LTI flow, mixed into LtiLaunchController.
# LTIAAS forwards an LtiDeepLinkingRequest (from the assignment_selection /
# link_selection placement) to #deep_link, which renders a picker of the bound
# course's gradables. The instructor's choice posts to #deep_link_select, which
# returns a single content item so Canvas creates an assignment tied to our
# tool (resource link + AGS line item) — giving later launches the `lineItemId`
# the assignment_view drill-down resolves.
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

    @gradables = DeepLinkableGradables.new(@binding.course).result
    render 'lti_launch/deep_link_picker', layout: 'lti_iframe'
  end

  def deep_link_select
    return redirect_to errors_login_error_path if params[:ltik].blank?

    @lti_session = build_lti_session(params[:ltik])
    return head :forbidden unless @lti_session.instructor?

    gradable = chosen_gradable(@lti_session.bound_binding)
    return head :unprocessable_entity if gradable.nil?

    @deep_link_form = BuildLtiDeepLinkForm.new(ltik: params[:ltik], gradable:).form
    render 'lti_launch/deep_link_form', layout: 'lti_iframe'
  end

  private

  # The gradable matching the submitted `resource`, re-derived from the bound
  # course so only that course's own gradables are accepted. nil if unbound or
  # the resource isn't one of them.
  def chosen_gradable(binding)
    return nil if binding.nil?

    DeepLinkableGradables.new(binding.course).result
                         .find { |gradable| gradable.resource == params[:resource] }
  end
end
