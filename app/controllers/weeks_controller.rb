# frozen_string_literal: true
class WeeksController < ApplicationController
  respond_to :json

  def destroy
    Week.find(params[:id]).destroy
    render plain: '', status: :ok
  end

  def delete_multiple
    all_weeks = params[:id]
    all_weeks.each do |w|
      Week.find(w).destroy
    end
    render plain: '', status: :ok
  end
end
