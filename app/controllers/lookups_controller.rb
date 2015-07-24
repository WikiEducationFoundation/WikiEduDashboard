#= Controller for user functionality
class LookupsController < ApplicationController
  include CourseHelper

  before_action :require_permissions
  respond_to :json

  def fetch_course
    return unless params.key? :course
    @course = find_course_by_slug(params[:course])
  end

  def cohort
    fetch_course
    @model = 'cohort'
    @key = 'title'
    @values = Cohort.all.pluck(:title)
    render 'index'
  end

  def tag
    fetch_course
    @model = 'tag'
    @key = 'tag'
    @values = Tag.all.pluck(:tag)
    render 'index'
  end

  def article
    fetch_course
    @model = 'article'
    @key = 'title'
    @values = Article.live.namespace(0).select('title').pluck(:title)
    @values.map! { |a| a.gsub('_', ' ') }
    render 'index'
  end

  def user
    fetch_course
    @model = 'user'
    @key = 'wiki_id'
    @values = User.all.select('wiki_id').pluck(:wiki_id)
    render 'index'
  end
end
