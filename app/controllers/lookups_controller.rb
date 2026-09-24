# frozen_string_literal: true

#= Controller for user functionality
class LookupsController < ApplicationController
  include CourseHelper

  respond_to :json

  CAMPAIGNS_PER_PAGE = 25

  # Used to generate list of existing campaigns for pulldown
  def campaign
    @model = 'campaign'
    @key = 'title'
    @values = Campaign.all.order(created_at: :desc)
    filter_campaigns
    paginate_campaigns if params[:page].present?
    render 'campaigns'
  end

  # Used to generate list of existing tags for pulldown
  def tag
    require_admin_permissions
    @model = 'tag'
    @key = 'tag'
    @values = Tag.all.pluck(:tag)
    render 'tags'
  end

  private

  def filter_campaigns
    return if params[:search].blank?

    escaped_search = Campaign.sanitize_sql_like(params[:search].downcase)
    @values = @values.where('lower(title) LIKE ?', "%#{escaped_search}%")
  end

  def paginate_campaigns
    @page = [params[:page].to_i, 1].max
    @total_count = @values.count
    @total_pages = (@total_count.to_f / CAMPAIGNS_PER_PAGE).ceil
    @values = @values.offset((@page - 1) * CAMPAIGNS_PER_PAGE).limit(CAMPAIGNS_PER_PAGE)
  end
end
