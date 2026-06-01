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
end
