# frozen_string_literal: true

class WeeksController < ApplicationController
  respond_to :json

  def destroy
    Week.find(params[:id]).destroy
    render plain: '', status: :ok
  end
end
