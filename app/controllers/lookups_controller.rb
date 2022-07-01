# frozen_string_literal: true

#= Controller for user functionality
class LookupsController < ApplicationController
  include CourseHelper

  respond_to :json

  # Used to generate list of existing campaigns for pulldown
  def campaign
    user_only = params[:user_only]
    newest = params[:newest]
    @model = 'campaign'
    @key = 'title'
    @values = user_only == 'true' ? current_user.campaigns : Campaign.all.order(created_at: :desc)
    @values = @values.limit(10) if newest == 'true'
    render user_only == 'true' ? 'user_campaigns' : 'campaigns'
  end

  # Used to generate list of existing tags for pulldown
  def tag
    require_admin_permissions
    @model = 'tag'
    @key = 'tag'
    @values = Tag.all.pluck(:tag)
    render 'tags'
  end
end
