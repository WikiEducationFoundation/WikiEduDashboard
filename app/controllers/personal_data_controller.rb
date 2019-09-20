# frozen_string_literal: true

# Allows users to download the personal data bout them stored on the Dashboard
class PersonalDataController < ApplicationController
  before_action :require_signed_in
  respond_to :json

  def show
    @user = current_user
  end
end
