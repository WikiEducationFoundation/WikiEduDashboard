#= Controller for user functionality
class UsersController < ApplicationController
  def revisions
    @revisions = Course.find(params[:course_id]).revisions
                 .where(user_id: params[:user_id]).order(date: :desc)
                 .limit(params[:limit].nil? ? 100 : params[:limit])
                 .drop(params[:drop].to_i || 0)
    revisions = { revisions: @revisions }
    r_list = render_to_string partial: 'revisions/list', locals: revisions
    r_list =  r_list.html_safe.gsub(/\n/, '').gsub(/\t/, '').gsub(/\r/, '')
    render json: { html: r_list, error: '' }
  end
end
