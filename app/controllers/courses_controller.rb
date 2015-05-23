require 'oauth'
require "#{Rails.root}/lib/wiki_edits"

#= Controller for course functionality
class CoursesController < ApplicationController
  def index
    if params.key?(:cohort)
      @cohort = Cohort.find_by(slug: params[:cohort])
    elsif !Figaro.env.default_cohort.nil?
      @cohort = Cohort.find_by(slug: Figaro.env.default_cohort)
    end
    @cohort ||= nil

    raise ActionController::RoutingError.new('Not Found') if @cohort.nil?

    @courses = @cohort.courses.where(listed: true).order(:title)
    @untrained = @courses.sum(:untrained_count)
    @trained = @courses.sum(:user_count) - @courses.sum(:untrained_count)
  end

  def students
    @course = Course.where(listed: true).find_by_slug(params[:id])
    raise ActionController::RoutingError.new('Not Found') if @course.nil?

    users = @course.users
    @courses_users = @course.courses_users
                     .includes(user: { assignments: :article })
                     .where(role: 0).order('users.wiki_id')
    @volunteers = users.role('online_volunteer') + users.role('campus_volunteer')
  end

  def articles
    @course = Course.where(listed: true).find_by_slug(params[:id])
    raise ActionController::RoutingError.new('Not Found') if @course.nil?

    users = @course.users
    @articles_courses = @course.articles_courses.live
                        .includes(:article).order('articles.title')
    @volunteers = users.role('online_volunteer') + users.role('campus_volunteer')
  end

  def manual_update
    @course = Course.where(listed: true).find_by_slug(params[:id])
    @course.manual_update if user_signed_in?
    redirect_to show_path(@course)
  end
  helper_method :manual_update

  def notify_untrained
    @course = Course.find(params[:course])
    return unless user_signed_in? && current_user.is_instructor(@course)
    WikiEdits.notify_untrained(params[:course], current_user)
    redirect_to show_path(@course)
  end
  helper_method :notify_untrained
end
