class WeeksController < ApplicationController
  respond_to :json

  def destroy
    Week.find(params[:id]).destroy
    render nothing: true
  end

end
