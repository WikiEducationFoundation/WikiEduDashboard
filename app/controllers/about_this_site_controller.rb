# frozen_string_literal: true

class AboutThisSiteController < ApplicationController
  respond_to :html

  def private_information; end

  # The published VPAT covers the Wiki Education Dashboard only; it
  # explicitly disclaims the P&E Dashboard deployment, so it is not
  # served there.
  def accessibility
    raise ActionController::RoutingError, 'Not Found' unless Features.wiki_ed?
  end

  # Public "how to install the Dashboard in Canvas" guide at /lti/guide.
  # Wiki-Ed-only, like the VPAT: the Canvas integration is a Wiki Education
  # Dashboard feature. Intentionally NOT behind the canvas_integration launch
  # flag, so prospective institutions can read it before the tool is enabled.
  def canvas_integration_guide
    raise ActionController::RoutingError, 'Not Found' unless Features.wiki_ed?
  end

  # The instructor-facing companion to the guide at /lti/guide/instructors:
  # the LTI 1.1 course-level install a teacher can do without an admin.
  def canvas_instructor_guide
    raise ActionController::RoutingError, 'Not Found' unless Features.wiki_ed?
  end

  # Public HECVAT (security/privacy assessment) for the Canvas integration,
  # published alongside the VPAT. Wiki-Ed-only, same as the VPAT.
  def hecvat
    raise ActionController::RoutingError, 'Not Found' unless Features.wiki_ed?
  end
end
