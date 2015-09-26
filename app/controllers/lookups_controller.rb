#= Controller for user functionality
class LookupsController < ApplicationController
  include CourseHelper

  before_action :require_permissions
  respond_to :json

  def cohort
    @model = 'cohort'
    @key = 'title'
    @values = Cohort.all.pluck(:title)
    render 'index'
  end

  def tag
    @model = 'tag'
    @key = 'tag'
    @values = Tag.all.pluck(:tag)
    render 'index'
  end

  def article
    @model = 'article'
    @key = 'title'
    @values = Article.live.namespace(0).select('title').pluck(:title)
    @values.map! { |a| a.gsub('_', ' ') }
    render 'index'
  end
end
