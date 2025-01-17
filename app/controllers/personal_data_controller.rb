# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/personal_data/personal_data_csv_builder.rb"

# Allows users to download the personal data about them stored on the Dashboard
class PersonalDataController < ApplicationController
  before_action :require_signed_in
  respond_to :csv, only: [:personal_data_csv]

  def show
    @user = current_user
  end

  def personal_data_csv
    @user = current_user
    csv_data = PersonalData::PersonalDataCsvBuilder.new(@user).generate_csv

    send_data csv_data,
              type: 'text/csv',
              disposition: 'attachment',
              filename: "#{@user.username}_personal_data_#{Time.zone.today}.csv"
  end
end
