# frozen_string_literal: true

# Admin-only overview of LMS integrations: every Canvas course that has launched
# the tool, and the Dashboard course it is bound to (if the instructor has
# finished setup). Not gated on Features.canvas_integration?: the bindings are
# plain rows, and staff may want to see them while the integration is switched
# off.
class LtiIntegrationsController < ApplicationController
  layout 'admin'
  before_action :require_admin_permissions

  def index
    @bindings = LtiCourseBinding.includes(:lti_contexts, course: :instructors)
                                .order(created_at: :desc)
  end
end
