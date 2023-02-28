# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/importers/user_importer"

class UpdateUsernameController < ApplicationController
  before_action :require_signed_in
  respond_to :html, :json
  def index
    @user = User
  end

  def update
    @username = params['username']
    user = UserImporter.update_username_for_changed_metawiki_usernames(@username)
    if @username.blank?
      flash[:error] = t('update_username.empty_username')
    elsif user.nil?
      flash[:error] = t('update_username.not_found')
    else
      flash[:notice] = t('update_username.username_updated')
    end
    redirect_to '/update_username'
  end
end
