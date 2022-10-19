class RosterController < ApplicationController
  before_action :require_signed_in
  respond_to :html, :json
  def update_roster
    @user = current_user
  end

  private

  def user_params
    params.require(:user).permit[:username, :global_id]
  end
end
