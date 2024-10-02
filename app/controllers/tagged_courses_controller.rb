# frozen_string_literal: true

#= Controller for collections of courses with a common tag
#= reusing the views from CampaignsController
class TaggedCoursesController < ApplicationController
  before_action :require_admin_permissions
  before_action :set_tag

  def articles
    set_page
    set_courses_and_presenter
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
    @wiki_experts = CoursesUsers.where(course: @courses, user: SpecialUsers.wikipedia_experts,
                                       role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
  end
end
