# frozen_string_literal: true
class BlocksController < ApplicationController
  respond_to :json

  def destroy
    Block.find(params[:id]).destroy
    render nothing: true
  end
end
