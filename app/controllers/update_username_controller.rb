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
    if @username.blank?
      flash[:error] = t('update_username.empty_username')
      redirect_to '/update_username'
    else
      user = UserImporter.update_username_for_changed_metawiki_usernames(@username)
      if user.nil?
        flash[:error] = t('update_username.not_found')
        redirect_to '/update_username'
      else
        flash[:notice] = t('update_username.username_updated')
        redirect_to '/update_username'
      end
    end
  end
end
