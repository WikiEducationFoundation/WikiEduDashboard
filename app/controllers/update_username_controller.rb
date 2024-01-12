# frozen_string_literal: true

require_dependency Rails.root.join('lib/importers/user_importer')

class UpdateUsernameController < ApplicationController
  before_action :require_signed_in
  respond_to :html, :json
  def index; end

  def update
    username = UserImporter.sanitize_username params['username']
    user = UserImporter.update_username_for_global_id username
    redirect_to '/update_username'
    return if username.blank?
    if user.nil?
      flash[:error] = t('update_username.not_found')
    else
      flash[:notice] = t('update_username.username_updated')
    end
  end
end
