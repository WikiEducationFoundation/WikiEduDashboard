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
        puts @username
        UserImporter.update_username_for_global_id(@username)
        redirect_to '/'
    end
end