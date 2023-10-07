# frozen_string_literal: true
require 'ostruct'

require_dependency "#{Rails.root}/lib/lift_wing_api"
require_dependency "#{Rails.root}/lib/wiki_api"


#=Controller for the Revisions API.
class RevisionsController < ApplicationController
  respond_to :json
  DEFAULT_REVISION_LIMIT = 10

  # Returns revisions for a single user within the scope of a single course.
  def index
    user = User.find(params[:user_id])
    course = Course.find(params[:course_id])

    @revisions = course.tracked_revisions.where(user_id: user.id)
                       .order('revisions.date DESC')
                       .eager_load(:article, :wiki)
                       .limit(params[:limit] || DEFAULT_REVISION_LIMIT)
  end

  def show
    revids =JSON.parse(params[:revids]).split("|")
    wiki = JSON.parse(params[:wiki])
    # convert wiki to object
    wiki = OpenStruct.new(wiki)

    wiki_key = "#{wiki.language || wiki.project}wiki"
    model_key ||= wiki.project == 'wikidata' ? 'itemquality' : 'articlequality'

    # convert each revids to integer
    revids = revids.map(&:to_i)

    # get article quality data
    articlequality_data = LiftWingApi.new(wiki, nil).get_revision_data(revids)

    render json: articlequality_data, status: 200
  end
end
