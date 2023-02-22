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
    UserImporter.update_username_for_changed_metawiki_usernames(@username)
    redirect_to '/'
  end
end
