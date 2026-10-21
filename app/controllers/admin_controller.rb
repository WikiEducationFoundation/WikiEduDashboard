# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/experiments/opt_in_experiment"

# Controller admin panel
class AdminController < ApplicationController
  def index
    check_user_auth
    # Opt-in experiments only run on the Wiki Education Dashboard.
    @opt_in_experiments = Features.wiki_ed? ? OptInExperiment.active : []
  end

  private

  def check_user_auth
    return if current_user&.admin?
    flash[:notice] = "You don't have access to that page."
    redirect_to root_path
  end
end
