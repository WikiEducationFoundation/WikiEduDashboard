# frozen_string_literal: true

#= Controller for user functionality
class LookupsController < ApplicationController
  include CourseHelper

  before_action :require_permissions
  respond_to :json

  # Used to generate list of existing campaigns for pulldown
  def campaign
    @model = 'campaign'
    @key = 'title'
    @values = Campaign.all.order(created_at: :desc).pluck(:title)
    render 'index'
  end

  # Used to generate list of existing tags for pulldown
  def tag
    @model = 'tag'
    @key = 'tag'
    @values = Tag.all.pluck(:tag)
    render 'index'
  end

  # FIXME: called by AssignButton, but the result is not used for anything.
  # It's been stubbed out for now, but the AssignButton should be modified to
  # not make this lookup at all.
  # See https://github.com/WikiEducationFoundation/WikiEduDashboard/issues/399
  def article
    @model = 'article'
    @key = 'title'
    @values = nil
    render 'index'
  end
end
