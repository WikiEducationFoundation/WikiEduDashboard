# frozen_string_literal: true

#= Controller for collections of courses with a common tag
#= reusing the views from CampaignsController
class TaggedCoursesController < ApplicationController
  before_action :require_admin_permissions
  before_action :set_tag

  def articles
    set_page
    set_courses_and_presenter
    render 'tagged_courses/articles'
  end

  def alerts
    set_courses_and_presenter
    respond_to do |format|
      format.html { render }
      format.json do
        @alerts = Alert.includes(:course, :user, article: :wiki).where(course: @courses)
      end
    end
  end

  def programs
    set_page
    set_courses_and_presenter
    load_wiki_experts
    render 'tagged_courses/programs'
  end

  private

  def set_page
    @page = params[:page]&.to_i
    @page = nil unless @page&.positive?
  end

  def set_tag
    @tag = params[:tag]
  end

  def set_courses_and_presenter
    @courses = Tag.courses_tagged_with(@tag)
    @presenter = CoursesPresenter.new(current_user:, tag: @tag,
                                      courses_list: @courses, page: @page)
  end

  # Loads CoursesUsers records with role 4 and filters by wiki experts, avoiding N+1 queries
  def load_wiki_experts
    return @wiki_experts if @wiki_experts # Avoid re-loading if already loaded

    course_ids = @courses.pluck(:id)
    wiki_experts_set = SpecialUsers.special_users[:wikipedia_experts]&.to_set

    @wiki_experts = CoursesUsers
                    .where(course_id: course_ids, role: 4)
                    .includes(:user)
                    .select { |course_user| wiki_experts_set.include?(course_user.user.username) }
                    .map { |course_user| { course_id: course_user.course_id, username: course_user.user.username } } # rubocop:disable Layout/LineLength
  end
end
